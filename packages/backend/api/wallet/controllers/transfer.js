'use strict';

const transferService = require('../services/transfer');
const utils = require('../services/utils');

/**
 * Transfer Controller
 * Handles wallet-to-wallet fund transfers
 */

// Configuration constants
const IDEMPOTENCY_TTL = 24 * 60 * 60 * 1000; // 24 hours
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 10;

module.exports = {
  /**
   * POST /wallet/lookup-user
   * Look up user by phone number
   */
  async lookupUser(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { phoneNumber } = ctx.request.body;

      if (!phoneNumber) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Phone number is required'));
      }

      // Normalize phone number (remove spaces, dashes)
      const normalizedPhone = phoneNumber.replace(/[\s\-\(\)]/g, '');

      strapi.log.info('[Transfer] Looking up user by phone:', {
        requestedBy: userId,
        phoneNumber: normalizedPhone.slice(-4), // Log last 4 digits only
      });

      // Search for user by phone number
      const knex = strapi.connections.default;
      const users = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .where({ phone: normalizedPhone })
        .limit(1);

      if (!users || users.length === 0) {
        return ctx.send(utils.successResponse({
          found: false,
          message: 'No user found with this phone number',
        }));
      }

      const targetUser = users[0];

      // Prevent self-transfer
      if (targetUser.id === userId) {
        return ctx.send(utils.successResponse({
          found: false,
          message: 'Cannot transfer to yourself',
        }));
      }

      // Check if target user has a wallet
      const wallet = await knex('wallets')
        .where({ user_id: targetUser.id })
        .first();

      if (!wallet) {
        return ctx.send(utils.successResponse({
          found: false,
          message: 'User does not have a wallet',
        }));
      }

      // Check if wallet is frozen
      if (wallet.status === 'frozen') {
        return ctx.send(utils.successResponse({
          found: false,
          message: 'Cannot transfer to this user',
        }));
      }

      ctx.send(utils.successResponse({
        found: true,
        user: {
          id: targetUser.id,
          username: targetUser.username,
          phoneNumber: normalizedPhone,
        },
      }));
    } catch (error) {
      strapi.log.error('[Transfer] lookupUser error:', error);
      ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', error.message));
    }
  },

  /**
   * POST /wallet/transfer
   * Initiate wallet-to-wallet transfer
   */
  async initiateTransfer(ctx) {
    try {
      const senderUserId = ctx.state.user.id;

      if (!senderUserId) {
        return ctx.unauthorized('Authentication required');
      }

      const {
        receiverUserId,
        amount,
        description,
        idempotencyKey,
      } = ctx.request.body;

      // Validate inputs
      if (!receiverUserId || !amount) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Receiver user ID and amount are required'));
      }

      if (!idempotencyKey) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Idempotency key is required'));
      }

      const knex = strapi.connections.default;

      // Check rate limiting using database (replaces in-memory cache)
      const now = new Date();
      const rateLimitWindowStart = new Date(Date.now() - RATE_LIMIT_WINDOW);

      const recentRequests = await knex('wallet_transfers')
        .where('sender_user_id', senderUserId)
        .where('created_at', '>=', rateLimitWindowStart)
        .count('* as count');

      const requestCount = parseInt(recentRequests[0].count);
      if (requestCount >= MAX_REQUESTS_PER_WINDOW) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Too many transfer requests. Please wait a moment.'));
      }

      // Check idempotency using database (replaces in-memory cache)
      // Look for existing transfer with same sender and idempotency key in the last 24 hours
      const idempotencyWindowStart = new Date(Date.now() - IDEMPOTENCY_TTL);
      const existingTransfer = await knex('wallet_transfers')
        .where('sender_user_id', senderUserId)
        .where('description', 'like', `%${idempotencyKey}%`)
        .where('created_at', '>=', idempotencyWindowStart)
        .where('status', '!=', 'failed')
        .orderBy('created_at', 'desc')
        .first();

      if (existingTransfer) {
        strapi.log.info('[Transfer] Returning existing transfer for idempotency key:', idempotencyKey);
        return ctx.send(utils.successResponse({
          success: true,
          transferId: existingTransfer.transfer_id,
          amount: parseFloat(existingTransfer.amount),
          fee: parseFloat(existingTransfer.fee || 0),
          totalDeduction: parseFloat(existingTransfer.amount) + parseFloat(existingTransfer.fee || 0),
          status: existingTransfer.status,
          timestamp: existingTransfer.created_at,
          idempotent: true,
        }));
      }

      // Validate amount
      const amountNum = parseFloat(amount);
      if (isNaN(amountNum) || amountNum <= 0) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Invalid amount'));
      }

      if (amountNum < 1) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Minimum transfer amount is ฿1'));
      }

      if (amountNum > 50000) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Maximum transfer amount is ฿50,000'));
      }

      // Validate receiver
      const receiverUserIdNum = parseInt(receiverUserId);
      if (isNaN(receiverUserIdNum)) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Invalid receiver user ID'));
      }

      // Prevent self-transfer
      if (senderUserId === receiverUserIdNum) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Cannot transfer to yourself'));
      }

      strapi.log.info('[Transfer] Initiating transfer:', {
        senderUserId,
        receiverUserId: receiverUserIdNum,
        amount: amountNum,
        idempotencyKey,
      });

      // Process transfer using transfer service
      const result = await transferService.transferFunds(
        senderUserId,
        receiverUserIdNum,
        amountNum,
        description || `Transfer to user ${receiverUserIdNum} [${idempotencyKey}]`
      );

      // Return result (idempotency now handled by database)
      const responseData = {
        success: true,
        transferId: result.transferId,
        amount: amountNum,
        fee: result.fee || 0,
        totalDeduction: result.totalDeduction,
        status: result.status,
        timestamp: new Date().toISOString(),
        idempotent: false,
      };

      ctx.send(utils.successResponse(responseData));
    } catch (error) {
      strapi.log.error('[Transfer] initiateTransfer error:', error);

      // Map service errors to user-friendly messages
      let errorCode = 'TRANSFER_ERROR';
      let errorMessage = error.message;

      if (error.message.includes('Insufficient balance')) {
        errorCode = 'WALLET_001';
      } else if (error.message.includes('frozen')) {
        errorCode = 'WALLET_002';
      } else if (error.message.includes('limit exceeded')) {
        errorCode = 'WALLET_003';
      }

      ctx.badRequest(utils.errorResponse(errorCode, errorMessage));
    }
  },

  /**
   * GET /wallet/transfers
   * Get transfer history
   */
  async getTransferHistory(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const {
        page = 1,
        limit = 20,
        type, // 'sent', 'received', or 'all'
      } = ctx.query;

      const offset = (parseInt(page) - 1) * parseInt(limit);

      strapi.log.info('[Transfer] Getting transfer history:', {
        userId,
        page,
        limit,
        type,
      });

      const knex = strapi.connections.default;
      let query = knex('wallet_transfers')
        .select(
          'transfer_id',
          'sender_user_id',
          'receiver_user_id',
          'amount',
          'fee',
          'status',
          'description',
          'created_at'
        )
        .orderBy('created_at', 'desc')
        .limit(parseInt(limit))
        .offset(offset);

      // Filter by type
      if (type === 'sent') {
        query = query.where({ sender_user_id: userId });
      } else if (type === 'received') {
        query = query.where({ receiver_user_id: userId });
      } else {
        // All transfers (sent or received)
        query = query.where(function() {
          this.where({ sender_user_id: userId })
            .orWhere({ receiver_user_id: userId });
        });
      }

      const transfers = await query;

      // Get total count
      let countQuery = knex('wallet_transfers')
        .count('* as count');

      if (type === 'sent') {
        countQuery = countQuery.where({ sender_user_id: userId });
      } else if (type === 'received') {
        countQuery = countQuery.where({ receiver_user_id: userId });
      } else {
        countQuery = countQuery.where(function() {
          this.where({ sender_user_id: userId })
            .orWhere({ receiver_user_id: userId });
        });
      }

      const [{ count }] = await countQuery;

      // Fix N+1 query: Fetch all unique user IDs in a single query
      const uniqueUserIds = new Set();
      transfers.forEach(transfer => {
        uniqueUserIds.add(transfer.sender_user_id);
        uniqueUserIds.add(transfer.receiver_user_id);
      });

      // Fetch all users at once (single query instead of N queries)
      const users = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .whereIn('id', Array.from(uniqueUserIds));

      // Create a map for O(1) lookup
      const userMap = {};
      users.forEach(user => {
        userMap[user.id] = user;
      });

      // Enrich transfers with user information (no database queries in loop)
      const enrichedTransfers = transfers.map(transfer => {
        const isSent = transfer.sender_user_id === userId;
        const otherUserId = isSent ? transfer.receiver_user_id : transfer.sender_user_id;
        const otherUser = userMap[otherUserId];

        return {
          transferId: transfer.transfer_id,
          type: isSent ? 'sent' : 'received',
          amount: parseFloat(transfer.amount),
          fee: parseFloat(transfer.fee || 0),
          status: transfer.status,
          description: transfer.description,
          createdAt: transfer.created_at,
          otherUser: otherUser ? {
            id: otherUser.id,
            username: otherUser.username,
            phoneNumber: otherUser.phone,
          } : null,
        };
      });

      ctx.send(utils.successResponse({
        transfers: enrichedTransfers,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(count),
          totalPages: Math.ceil(parseInt(count) / parseInt(limit)),
        },
      }));
    } catch (error) {
      strapi.log.error('[Transfer] getTransferHistory error:', error);
      ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', error.message));
    }
  },

  /**
   * GET /wallet/transfer/:transferId
   * Get transfer details
   */
  async getTransferDetails(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { transferId } = ctx.params;

      if (!transferId) {
        return ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', 'Transfer ID is required'));
      }

      const knex = strapi.connections.default;
      const transfer = await knex('wallet_transfers')
        .where({ transfer_id: transferId })
        .first();

      if (!transfer) {
        return ctx.notFound(utils.errorResponse('TRANSFER_ERROR', 'Transfer not found'));
      }

      // Check authorization (user must be sender or receiver)
      if (transfer.sender_user_id !== userId && transfer.receiver_user_id !== userId) {
        return ctx.forbidden(utils.errorResponse('TRANSFER_ERROR', 'Access denied'));
      }

      // Get sender info
      const sender = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .where({ id: transfer.sender_user_id })
        .first();

      // Get receiver info
      const receiver = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .where({ id: transfer.receiver_user_id })
        .first();

      ctx.send(utils.successResponse({
        transferId: transfer.transfer_id,
        amount: parseFloat(transfer.amount),
        fee: parseFloat(transfer.fee || 0),
        status: transfer.status,
        description: transfer.description,
        createdAt: transfer.created_at,
        sender: sender ? {
          id: sender.id,
          username: sender.username,
          phoneNumber: sender.phone,
        } : null,
        receiver: receiver ? {
          id: receiver.id,
          username: receiver.username,
          phoneNumber: receiver.phone,
        } : null,
      }));
    } catch (error) {
      strapi.log.error('[Transfer] getTransferDetails error:', error);
      ctx.badRequest(utils.errorResponse('TRANSFER_ERROR', error.message));
    }
  },
};