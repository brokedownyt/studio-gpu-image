# Studio GPU image for Vast.ai (user ask 23 Nov 2026: "setup bar bar na karna pade").
# Base = wahi image jo vast-job.ps1 pehle se use karta tha (hosts par aksar cached), upar sirf hamare tools.
# Targets:  render  = ffmpeg (NVENC) + Chrome deps + fonts + Node 20.18.0 + @remotion/renderer 4.0.537
#                     + headless shell + Playwright 1.56.0 Chromium
#           blender = render + Blender 4.2.3
# NVIDIA GL/EGL libs driver version se bante hain (host par), isliye wo run.sh hi runtime par nikalta hai.
# Koi key/token image me nahi.
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS render
LABEL org.opencontainers.image.source=https://github.com/brokedownyt/studio-gpu-image
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
      curl ca-certificates xz-utils unzip rsync ffmpeg \
      libegl1 libvulkan1 libnss3 libdbus-1-3 libatk1.0-0 libgbm-dev libasound2 libxrandr2 libxkbcommon-dev \
      libxfixes3 libxcomposite1 libxdamage1 libatk-bridge2.0-0 libpango-1.0-0 libcairo2 libcups2 \
      fonts-noto-core fonts-noto-color-emoji fonts-dejavu-core \
 && rm -rf /var/lib/apt/lists/*
# Naya ffmpeg 7.1 (BtbN static, NVENC): Ubuntu ka ffmpeg 4.4 naye driver (595.x, RTX 4090) par
# "OpenEncodeSessionEx failed: unsupported device" deta hai (14/15/23 Nov logs). /usr/local/bin PATH me /usr/bin se pehle.
RUN curl -sfL https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n7.1-latest-linux64-gpl-7.1.tar.xz | tar -xJ -C /opt \
 && ln -s /opt/ffmpeg-n7.1-latest-linux64-gpl-7.1 /opt/ffmpeg \
 && ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe \
 && /usr/local/bin/ffmpeg -hide_banner -encoders | grep -q h264_nvenc
# Node 20.18.0 (run.sh wala version)
RUN curl -sfL https://nodejs.org/dist/v20.18.0/node-v20.18.0-linux-x64.tar.xz | tar -xJ -C /opt \
 && ln -s /opt/node-v20.18.0-linux-x64 /opt/node
ENV PATH=/opt/node/bin:$PATH
# /root/node_modules: /root/work ke scripts parent folder se resolve kar lete hain (Node ESM/CJS dono)
WORKDIR /root
RUN npm init -y >/dev/null && npm pkg set type=module \
 && npm i -s @remotion/renderer@4.0.537 playwright@1.56.0 \
 && npx playwright install --with-deps chromium \
 && node -e "import('@remotion/renderer').then(r=>r.ensureBrowser()).then(()=>console.log('shell ok'))" \
 && rm -rf /var/lib/apt/lists/* /root/.npm
# env.sh: run.sh isse source karke install steps skip karta hai
RUN set -e; mkdir -p /opt/studio; \
    exe=$(ls -d /root/.cache/ms-playwright/chromium-*/chrome-linux/chrome | sort | tail -1); \
    hs=$(find /root/node_modules/.remotion -name chrome-headless-shell -type f 2>/dev/null | head -1); \
    test -x "$exe"; test -x "$hs"; \
    printf 'export PATH=/opt/node/bin:$PATH\nexport STUDIO_PW_CHROME=%s\nexport STUDIO_HS=%s\n' "$exe" "$hs" > /opt/studio/env.sh; \
    ffmpeg -hide_banner -encoders 2>/dev/null | grep -q h264_nvenc; \
    echo "render-v1 $(date -u +%F)" > /opt/studio/READY; cat /opt/studio/env.sh

FROM render AS blender
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
      libxi6 libxxf86vm1 libxrender1 libsm6 libgl1 libxext6 \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sfL https://download.blender.org/release/Blender4.2/blender-4.2.3-linux-x64.tar.xz | tar -xJ -C /opt \
 && ln -sf /opt/blender-4.2.3-linux-x64/blender /usr/local/bin/blender \
 && echo "blender-v1 $(date -u +%F)" >> /opt/studio/READY
