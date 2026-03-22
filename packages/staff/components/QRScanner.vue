<template>
  <div class="container">
    <div class="qrcode-reader-wrapper">
      <qrcode-stream
        :camera="cameraSettings"
        :track="paintBoundingBox"
        @decode="onDecode"
        @init="onInit"
      >
        <div v-if="loading" class="loading-indicator">
          <i class="fas fa-spinner fa-spin"></i>
          <p>กำลังเปิดกล้อง...</p>
        </div>

        <!-- Torch toggle button -->
        <div v-if="!loading && !error && torchSupported" class="torch-toggle">
          <button @click="toggleTorch" class="torch-button">
            <i :class="torchActive ? 'fas fa-lightbulb' : 'far fa-lightbulb'"></i>
          </button>
        </div>

        <!-- Scan frame guide -->
        <div v-if="!loading && !error" class="scan-frame">
          <div class="corner top-left"></div>
          <div class="corner top-right"></div>
          <div class="corner bottom-left"></div>
          <div class="corner bottom-right"></div>
        </div>
      </qrcode-stream>
    </div>
    <p v-if="error" class="error-message">{{ error }}</p>
    <p v-if="!loading && !error" class="scan-hint">วาง QR Code ให้อยู่ในกรอบ</p>
  </div>
</template>

<script>
export default {
  data() {
    return {
      // Simplified settings that work on both mobile and desktop
      cameraSettings: 'auto',
      loading: true,
      error: null,
      result: null,
      torchSupported: false,
      torchActive: false,
      mediaStream: null,
      detectionActive: true,
    }
  },
  methods: {
    onDecode(result) {
      if (!this.detectionActive) return

      console.log('[QRScanner] QR Code scanned:', result.substring(0, 50) + '...')

      // Haptic feedback (vibration) like iPhone
      if (navigator.vibrate) {
        navigator.vibrate(100)
      }

      this.result = result
      this.detectionActive = false

      // Pause camera after successful scan
      this.cameraSettings = 'off'

      this.$emit('decode', result)
    },

    async onInit(promise) {
      this.loading = true
      console.log('[QRScanner] Initializing camera...')

      try {
        const result = await promise
        console.log('[QRScanner] Camera initialized successfully')
        console.log('[QRScanner] Result:', result)

        // Check capabilities if available
        if (result && result.capabilities) {
          console.log('[QRScanner] Camera capabilities:', result.capabilities)

          // Check if torch/flashlight is supported
          if (result.capabilities.torch) {
            this.torchSupported = true
            console.log('[QRScanner] Torch supported')
          }
        }

        this.error = null
        console.log('[QRScanner] Scanner ready - point camera at QR code')
      } catch (error) {
        console.error('[QRScanner] Camera initialization error:', error)
        console.error('[QRScanner] Error name:', error.name)
        console.error('[QRScanner] Error message:', error.message)

        if (error.name === 'NotAllowedError') {
          this.error = 'กรุณาอนุญาตการใช้งานกล้อง - คลิก "Allow" ที่ด้านบนของเบราว์เซอร์'
        } else if (error.name === 'NotFoundError') {
          this.error = 'ไม่พบกล้อง - ตรวจสอบว่ากล้องเชื่อมต่อแล้ว'
        } else if (error.name === 'NotSupportedError') {
          this.error = 'เบราว์เซอร์ไม่รองรับการใช้งานกล้อง (ต้องใช้ HTTPS หรือ localhost)'
        } else if (error.name === 'NotReadableError') {
          this.error = 'ไม่สามารถเข้าถึงกล้องได้ - ปิดแอพอื่นที่ใช้งานกล้องแล้วลองใหม่'
        } else if (error.name === 'OverconstrainedError') {
          this.error = 'กล้องไม่รองรับการตั้งค่าที่ระบุ'
        } else if (error.name === 'StreamApiNotSupportedError') {
          this.error = 'เบราว์เซอร์ไม่รองรับ Stream API - ลองใช้ Chrome หรือ Safari'
        } else {
          this.error = `ไม่สามารถเปิดกล้องได้: ${error.message}`
        }
      } finally {
        this.loading = false
      }
    },

    async toggleTorch() {
      if (!this.torchSupported) return

      try {
        const stream = this.$el.querySelector('video').srcObject
        const track = stream.getVideoTracks()[0]

        await track.applyConstraints({
          advanced: [{ torch: !this.torchActive }]
        })

        this.torchActive = !this.torchActive
        console.log('[QRScanner] Torch:', this.torchActive ? 'ON' : 'OFF')
      } catch (error) {
        console.error('[QRScanner] Torch toggle error:', error)
      }
    },

    paintBoundingBox(detectedCodes, ctx) {
      if (detectedCodes && detectedCodes.length > 0) {
        console.log('[QRScanner] QR code detected in frame!', detectedCodes.length, 'code(s)')
      }

      for (const detectedCode of detectedCodes) {
        const { boundingBox: { x, y, width, height } } = detectedCode
        console.log('[QRScanner] Drawing box at:', { x, y, width, height })

        // Draw green box when QR detected (like iPhone)
        ctx.lineWidth = 4
        ctx.strokeStyle = '#34C759' // iOS green
        ctx.shadowBlur = 10
        ctx.shadowColor = '#34C759'
        ctx.strokeRect(x, y, width, height)

        // Draw corner markers
        const cornerLength = 20
        ctx.lineWidth = 6

        // Top-left
        ctx.beginPath()
        ctx.moveTo(x, y + cornerLength)
        ctx.lineTo(x, y)
        ctx.lineTo(x + cornerLength, y)
        ctx.stroke()

        // Top-right
        ctx.beginPath()
        ctx.moveTo(x + width - cornerLength, y)
        ctx.lineTo(x + width, y)
        ctx.lineTo(x + width, y + cornerLength)
        ctx.stroke()

        // Bottom-left
        ctx.beginPath()
        ctx.moveTo(x, y + height - cornerLength)
        ctx.lineTo(x, y + height)
        ctx.lineTo(x + cornerLength, y + height)
        ctx.stroke()

        // Bottom-right
        ctx.beginPath()
        ctx.moveTo(x + width - cornerLength, y + height)
        ctx.lineTo(x + width, y + height)
        ctx.lineTo(x + width, y + height - cornerLength)
        ctx.stroke()
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.container {
  max-width: 480px;
  margin: 0 auto;
}

.qrcode-reader-wrapper {
  position: relative;
  width: 100%;
  min-height: 400px;
  background: #000;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.loading-indicator {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
  color: #fff;
  z-index: 10;

  i {
    font-size: 48px;
    margin-bottom: 12px;
    color: #1797ad;
  }

  p {
    margin: 0;
    font-size: 14px;
    color: #ccc;
    font-weight: 500;
  }
}

.torch-toggle {
  position: absolute;
  top: 16px;
  right: 16px;
  z-index: 15;

  .torch-button {
    width: 48px;
    height: 48px;
    border-radius: 24px;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(10px);
    border: none;
    color: #fff;
    font-size: 20px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s ease;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);

    &:hover {
      background: rgba(0, 0, 0, 0.8);
      transform: scale(1.05);
    }

    &:active {
      transform: scale(0.95);
    }

    i {
      transition: color 0.3s ease;
    }

    &:has(.fa-lightbulb.fas) {
      i {
        color: #ffd60a;
      }
    }
  }
}

.scan-frame {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 260px;
  height: 260px;
  pointer-events: none;
  z-index: 5;

  .corner {
    position: absolute;
    width: 40px;
    height: 40px;
    border: 4px solid #fff;
    box-shadow: 0 0 12px rgba(255, 255, 255, 0.6);

    &.top-left {
      top: 0;
      left: 0;
      border-right: none;
      border-bottom: none;
      border-top-left-radius: 8px;
    }

    &.top-right {
      top: 0;
      right: 0;
      border-left: none;
      border-bottom: none;
      border-top-right-radius: 8px;
    }

    &.bottom-left {
      bottom: 0;
      left: 0;
      border-right: none;
      border-top: none;
      border-bottom-left-radius: 8px;
    }

    &.bottom-right {
      bottom: 0;
      right: 0;
      border-left: none;
      border-top: none;
      border-bottom-right-radius: 8px;
    }
  }

  // Animated scanning line effect
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 2px;
    background: linear-gradient(90deg, transparent, #34C759, transparent);
    animation: scan 2s ease-in-out infinite;
    box-shadow: 0 0 8px #34C759;
  }

  @keyframes scan {
    0%, 100% {
      transform: translateY(0);
      opacity: 0;
    }
    10% {
      opacity: 1;
    }
    90% {
      opacity: 1;
    }
    100% {
      transform: translateY(260px);
      opacity: 0;
    }
  }
}

.scan-hint {
  text-align: center;
  margin-top: 16px;
  color: #666;
  font-size: 14px;
  font-weight: 500;
  letter-spacing: 0.2px;
}

.error-message {
  color: #dc3545;
  background: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 12px;
  padding: 16px;
  margin-top: 16px;
  text-align: center;
  font-size: 14px;
  line-height: 1.6;
  font-weight: 500;
}

// Override vue-qrcode-reader default styles
:deep(video) {
  width: 100%;
  height: 100%;
  min-height: 400px;
  object-fit: cover;
}

:deep(.qrcode-stream-camera) {
  width: 100%;
  min-height: 400px;
}

// Hide default scanner overlay if any
:deep(.qrcode-stream-overlay) {
  display: none;
}
</style>
