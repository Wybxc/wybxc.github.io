$('body').ready(function () {
    $("script[type='math/tex']").replaceWith(function() {
        const tex = $(this).text();
        return '$$' + tex + '$$';
    });
  
    $("script[type='math/tex; mode=display']").replaceWith(function() {
        const tex = $(this).html();
        return '<p>\\[' + tex + '\\]</p>'
    });

    const hasEquation = /(\$\$.*\$\$)|(\\\(.*\\\))|(\\\[.*\]\\)/.test($('#main').text())
    if (hasEquation) {
        window.MathJax = {
            tex: {
                inlineMath: [
                    ['$$', '$$']
                ],
                displayMath: [
                    ['\\[', '\\]'],                    
                ],
            },
        };
        $.getScript('https://cdn.bootcss.com/mathjax/3.0.5/es5/tex-svg.js');
    }
})