$('body').ready(function () {
    const hasEquation = /(\$\$.*\$\$)|(\\\(.*\\\))/.test($('#main').text())
    if (hasEquation) {
        window.MathJax = {
            tex: {
                inlineMath: [
                    ['\\(', '\\)']
                ],
                displayMath: [
                    ['$$', '$$'],
                    ['\\[', '\\]']
                ],
            },
        };
        $.getScript('https://cdn.bootcss.com/mathjax/3.0.5/es5/tex-mml-chtml.js');
    }
})