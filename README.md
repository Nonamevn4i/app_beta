# NEXUS Overlay - Android Performance Monitor

Real-time floating performance HUD for Android gaming tablets (RedMagic Nova, ROG Phone, etc.).

## Features
- **Real-time FPS** - Live frame counter for 120Hz+ displays
- **CPU/GPU Telemetry** - Per-core usage, frequencies, governor status
- **Temperature Monitoring** - CPU, GPU, and battery thermal readings
- **Network Analytics** - Download/upload speed, ping, latency
- **Battery Stats** - Level, temperature, voltage, charging status
- **Floating Overlay** - Draggable HUD above all apps
- **Gemini AI Advisor** - AI-powered optimization suggestions
- **Cyberpunk UI** - AMOLED dark theme, neon glow effects

## Build on Codemagic
1. Push to GitHub repo
2. Connect repo to [codemagic.io](https://codemagic.io)
3. Add env variable `GEMINI_API_KEY` in Codemagic UI
4. Build → download APK from Artifacts
