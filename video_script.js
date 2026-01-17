
(function () {
  const v = document.querySelector("video");

  function fitContain() {
    const vw = v.videoWidth;
    const vh = v.videoHeight;
    if (!vw || !vh) return;

    const ww = window.innerWidth;
    const wh = window.innerHeight;

    // 画面からはみ出さない最大サイズ
    const scale = Math.min(ww / vw, wh / vh);

    v.style.width  = Math.floor(vw * scale) + "px";
    v.style.height = Math.floor(vh * scale) + "px";
  }

  v.addEventListener("loadedmetadata", fitContain);
  window.addEventListener("resize", fitContain);
  window.addEventListener("orientationchange", fitContain);

  // 念のため即1回
  fitContain();
})();
