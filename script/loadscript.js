const loadScript = (f, src) => $('body').ready(() => f() ? $.getScript(src) : null);
// MathJax
loadScript(() => /(\$\$.*\$\$)|(\\\(.*\\\))/.test($('#main').text()), 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.4/latest.js?config=TeX-AMS_HTML');