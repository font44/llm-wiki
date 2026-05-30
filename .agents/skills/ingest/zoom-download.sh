#!/usr/bin/env bash
set -euo pipefail
url="$1"; name="${2:-recording.mp4}"
agent-browser open "$url" >/dev/null
agent-browser wait --load networkidle >/dev/null
cat <<EOF | agent-browser eval --stdin
(async () => {
  for (let i = 0; i < 30; i++) {
    const v = document.querySelector('video');
    if (v?.currentSrc) break;
    await new Promise(r => setTimeout(r, 500));
  }
  const v = document.querySelector('video');
  const r = await fetch(v.currentSrc, {credentials:'include'});
  const blob = await r.blob();
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = '$name';
  document.body.appendChild(a); a.click();
  return JSON.stringify({size: blob.size, duration: v.duration});
})()
EOF
