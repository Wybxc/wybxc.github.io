#import "/components/icons.typ": icon

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
    ```,
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
    ```,
  ) <aster-script>
  #html.script(
    "(function(){try{var t=localStorage.getItem('theme');if(t==='light'||t==='dark')document.documentElement.setAttribute('data-theme',t)}catch(e){}})()",
  )
  #html.a(
    class: "theme-toggle",
    aria-label: "Theme",
    {
      icon("lucide:sun", class: "theme-icon theme-icon-sun")
      icon("lucide:moon", class: "theme-icon theme-icon-moon")
      icon("lucide:monitor", class: "theme-icon theme-icon-monitor")
    },
  )
]
