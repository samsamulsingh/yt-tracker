// topbar.js - Simple site-wide progress indicator
// https://github.com/buunguyen/topbar
// License: MIT
(function(window, document) {
  "use strict";
  
  var canvas, currentProgress, showing, progressTimerId = null,
      fadeTimerId = null, delayTimerId = null, addEvent, options = {
        autoRun      : true,
        barThickness : 3,
        barColors    : {
          '0'      : 'rgba(26,  188, 156, .9)',
          '.25'    : 'rgba(52,  152, 219, .9)',
          '.50'    : 'rgba(241, 196, 15,  .9)',
          '.75'    : 'rgba(230, 126, 34,  .9)',
          '1.0'    : 'rgba(211, 84,  0,   .9)'
        },
        shadowBlur   : 10,
        shadowColor  : 'rgba(0,   0,   0,   .6)',
        className    : null
      }, repaint = function () {
        canvas.width = window.innerWidth;
        canvas.height = options.barThickness * 2;
        var ctx = canvas.getContext('2d');
        ctx.shadowBlur = options.shadowBlur;
        ctx.shadowColor = options.shadowColor;
        var lineGradient = ctx.createLinearGradient(0, 0, canvas.width, 0);
        for (var stop in options.barColors)
          lineGradient.addColorStop(stop, options.barColors[stop]);
        ctx.lineWidth = options.barThickness;
        ctx.beginPath();
        ctx.moveTo(0, options.barThickness / 2);
        ctx.lineTo(Math.ceil(currentProgress * canvas.width), options.barThickness / 2);
        ctx.strokeStyle = lineGradient;
        ctx.stroke();
      }, createCanvas = function() {
        canvas = document.createElement('canvas');
        var style = canvas.style;
        style.position = 'fixed';
        style.top = style.left = style.right = style.margin = style.padding = 0;
        style.zIndex = 100001;
        style.display = 'none';
        if (options.className) canvas.classList.add(options.className);
        document.body.appendChild(canvas);
        addEvent(window, 'resize', repaint);
      }, topbar = {
        config: function(opts) {
          for (var key in opts)
            if (options.hasOwnProperty(key))
              options[key] = opts[key];
        },
        show: function(delay) {
          if (showing) return;
          if (delay) {
            if (delayTimerId) return;
            delayTimerId = setTimeout(() => topbar.show(), delay);
          } else  {
            showing = true;
            if (fadeTimerId !== null)
              window.cancelAnimationFrame(fadeTimerId);
            if (!canvas) createCanvas();
            canvas.style.opacity = 1;
            canvas.style.display = 'block';
            topbar.progress(0);
            if (options.autoRun) {
              (function loop() {
                progressTimerId = window.requestAnimationFrame(loop);
                topbar.progress('+' + .05 * Math.pow(1 - Math.sqrt(currentProgress), 2));
              })();
            }
          }
        },
        progress: function(to) {
          if (typeof to === 'string') {
            to = (to.indexOf('+') >= 0 || to.indexOf('-') >= 0
                ? currentProgress
                : 0) + parseFloat(to);
          }
          currentProgress = to > 1 ? 1 : to;
          repaint();
          return currentProgress;
        },
        hide: function() {
          clearTimeout(delayTimerId);
          delayTimerId = null;
          if (!showing) return;
          showing = false;
          if (progressTimerId != null) {
            window.cancelAnimationFrame(progressTimerId);
            progressTimerId = null;
          }
          (function loop() {
            if (topbar.progress('+.1') >= 1) {
              canvas.style.opacity -= .05;
              if (canvas.style.opacity <= .05) {
                canvas.style.display = 'none';
                fadeTimerId = null;
                return;
              }
            }
            fadeTimerId = window.requestAnimationFrame(loop);
          })();
        }
      };
  // Set to window for use in browser
  if (typeof window !== 'undefined') {
    window.topbar = topbar;
  }
  
  addEvent = function(element, type, handler) {
    if (element.addEventListener) element.addEventListener(type, handler, false);
    else if (element.attachEvent) element.attachEvent('on' + type, handler);
    else element['on' + type] = handler;
  };
}).call(typeof window !== 'undefined' ? window : {}, typeof window !== 'undefined' ? window : {}, typeof document !== 'undefined' ? document : {});

export default typeof window !== 'undefined' && window.topbar ? window.topbar : {
  config: () => {},
  show: () => {},
  progress: () => {},
  hide: () => {}
};
