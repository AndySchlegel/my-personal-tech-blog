// Animated counter -- counts from 0 to target value when scrolled into view.
// Usage: <span data-count-to="50" data-count-suffix="+">0</span>
// The element text will animate from 0 to 50, then show "50+".

(function () {
  "use strict";

  var DURATION = 2000; // ms
  var STEP_MS = 30; // update interval

  function easeOut(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  function animateCounter(el) {
    var target = parseInt(el.getAttribute("data-count-to"), 10);
    var suffix = el.getAttribute("data-count-suffix") || "";
    if (isNaN(target)) return;

    var start = 0;
    var startTime = null;

    function step(timestamp) {
      if (!startTime) startTime = timestamp;
      var elapsed = timestamp - startTime;
      var progress = Math.min(elapsed / DURATION, 1);
      var value = Math.round(easeOut(progress) * target);

      el.textContent =
        value.toLocaleString("en-US") + (progress >= 1 ? suffix : "");

      if (progress < 1) {
        requestAnimationFrame(step);
      }
    }

    el.textContent = "0";
    requestAnimationFrame(step);
  }

  function init() {
    var elements = document.querySelectorAll("[data-count-to]");
    if (!elements.length) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            animateCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.3 },
    );

    elements.forEach(function (el) {
      el.textContent = "0";
      observer.observe(el);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
