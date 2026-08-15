#let _init-js = "(function(){try{var t=localStorage.getItem('theme');if(t==='light'||t==='dark')document.documentElement.setAttribute('data-theme',t)}catch(e){}})()"

#let _svg-attrs = (
  xmlns: "http://www.w3.org/2000/svg",
  width: "1em",
  height: "1em",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  "stroke-width": "2",
  "stroke-linecap": "round",
  "stroke-linejoin": "round",
)

#let _sun-icon = html.elem("svg", attrs: _svg-attrs + (class: "theme-icon theme-icon-sun"))[
  #html.elem("circle", attrs: (cx: "12", cy: "12", r: "4"))
  #html.elem("path", attrs: (d: "M12 2v2"))
  #html.elem("path", attrs: (d: "M12 20v2"))
  #html.elem("path", attrs: (d: "m4.93 4.93 1.41 1.41"))
  #html.elem("path", attrs: (d: "m17.66 17.66 1.41 1.41"))
  #html.elem("path", attrs: (d: "M2 12h2"))
  #html.elem("path", attrs: (d: "M20 12h2"))
  #html.elem("path", attrs: (d: "m6.34 17.66-1.41 1.41"))
  #html.elem("path", attrs: (d: "m19.07 4.93-1.41 1.41"))
]

#let _moon-icon = html.elem("svg", attrs: _svg-attrs + (class: "theme-icon theme-icon-moon"))[
  #html.elem("path", attrs: (d: "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"))
]

#let _monitor-icon = html.elem("svg", attrs: _svg-attrs + (class: "theme-icon theme-icon-monitor"))[
  #html.elem("rect", attrs: (x: "2", y: "3", width: "20", height: "14", rx: "2"))
  #html.elem("path", attrs: (d: "M8 21h8"))
  #html.elem("path", attrs: (d: "M12 17v4"))
]

#let theme-toggle = [
  #metadata(
    ```css
    .theme-toggle {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 0;
      border: none;
      border-radius: 9999px;
      background: transparent;
      color: var(--color-content);
      cursor: pointer;
    }

    .theme-toggle .theme-icon {
      display: none;
    }

    .theme-toggle:not([data-current]) .theme-icon-monitor,
    .theme-toggle[data-current="light"] .theme-icon-sun,
    .theme-toggle[data-current="dark"] .theme-icon-moon,
    .theme-toggle[data-current="system"] .theme-icon-monitor {
      display: block;
    }
    ```
  ) <aster-style>
  #metadata(
    ```js
    (function () {
      var STORAGE_KEY = "theme";
      var MODES = ["light", "dark", "system"];
      var LABELS = { light: "Light", dark: "Dark", system: "System" };
      var root = document.documentElement;
      var toggle = document.querySelector(".theme-toggle");

      if (!toggle) {
        return;
      }

      function getStoredMode() {
        try {
          var stored = localStorage.getItem(STORAGE_KEY);
          return MODES.indexOf(stored) >= 0 ? stored : "system";
        } catch (error) {
          return "system";
        }
      }

      function apply() {
        var mode = getStoredMode();
        if (mode === "light" || mode === "dark") {
          root.setAttribute("data-theme", mode);
        } else {
          root.removeAttribute("data-theme");
        }
        toggle.setAttribute("data-current", mode);
        toggle.setAttribute("aria-label", "Theme: " + LABELS[mode]);
      }

      function cycle() {
        var mode = getStoredMode();
        var next = MODES[(MODES.indexOf(mode) + 1) % MODES.length];
        try {
          localStorage.setItem(STORAGE_KEY, next);
        } catch (error) {
          // Storage can be unavailable (private mode, blocked cookies); the
          // choice still applies for this page load.
        }
        apply();
      }

      apply();

      toggle.addEventListener("click", cycle);
    })();
    ```
  ) <aster-script>
  #html.script(_init-js)
  // #html.elem("button", attrs: (
  //   type: "button",
  //   class: "theme-toggle",
  //   "aria-label": "Theme",
  // ))[#_sun-icon#_moon-icon#_monitor-icon]
  #html.a(
    class: "theme-toggle",
    aria-label: "Theme"
  )[#_sun-icon#_moon-icon#_monitor-icon]
]
