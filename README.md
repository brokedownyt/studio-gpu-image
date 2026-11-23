# studio-gpu-image

Vast.ai jobs ke liye Docker image (`ghcr.io/brokedownyt/studio-gpu`). Isme tools pehle se install hain, taaki har job par setup na chale.

- `render-v1`: CUDA 12.4.1 devel base, ffmpeg 7.1 static (NVENC, /usr/local/bin) + Ubuntu ffmpeg 4.4, Chrome libs + fonts, Node 20.18.0, @remotion/renderer 4.0.537 + headless shell, Playwright 1.56.0 Chromium
- `blender-v1`: render-v1 + Blender 4.2.3

Image tab banti hai jab `Dockerfile` badle, ya Actions tab me "Run workflow" chalao. Image me koi key ya token nahi hai.
`/opt/studio/env.sh` me `PATH`, `STUDIO_PW_CHROME` aur `STUDIO_HS` hain. Inke saath `/opt/studio/READY` file bhi hai.
