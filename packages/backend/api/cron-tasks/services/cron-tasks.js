'use strict';

const moment = require('moment');
/**
 * Read the documentation (https://strapi.io/documentation/developer-docs/latest/development/backend-customization.html#core-services)
 * to customize this service
 */

module.exports = {
  async wrapTask(callback, { cron, key }) {
    const cronTask = await strapi.services['cron-tasks']
      .create({
        name: cron,
        transaction_key: key,
      });
    let taskStatus = "completed";
    let message = "";
    try {
      await callback();
    } catch (e) {
      taskStatus = "failed";
      message = e.message;
    }

    await strapi.services['cron-tasks']
      .update({ id: cronTask.id }, { status: taskStatus, message });
  },
  async cleanHistory() {
    try {
      await strapi.services['cron-tasks']
        .delete({
          created_at_lte: moment(nowLocal).subtract(7, 'days').format('YYYY-MM-DD'),
        });
    } catch (e) {
      strapi.log.error(`[CronTasks][cleanHistory] error:`, e);
    }
  }
};
