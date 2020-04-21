$('body').ready(function () {
    $("script[type='math/tex']").replaceWith(function () {
        const tex = $(this).text();
        return '$$' + tex + '$$';
    });

    $("script[type='math/tex; mode=display']").replaceWith(function () {
        const tex = $(this).html();
        return '<p>\\[' + tex + '\\]</p>'
    });

    const hasEquation = /(\$\$.*\$\$)|(\\\(.*\\\))|(\\\[.*\]\\)/.test($('#main').text())
    if (hasEquation) {
        $mask = $('#mask');
        $mask.css({
            'background-color': 'white',
            'opacity': '0',
            'z-index': '60',
        }).animate({ opacity: '0.75' }, 250).append('<div style="position: relative;top: 40%;margin: 0 auto;">' +
            '<i class="fa fa-spinner fa-pulse fa-3x fa-fw"></i>' +
            '<p>加载 Mathjax 中……</p>' +
            '</div>');
        window.MathJax = {
            tex: {
                inlineMath: [
                    ['$$', '$$']
                ],
                displayMath: [
                    ['\\[', '\\]'],
                ],
            },
            startup: {
                ready: function () {
                    MathJax.startup.defaultReady();
                    MathJax.startup.promise.then(() => {
                        $mask.animate({ opacity: '0' }, 300, function () {
                            $mask.css('z-index', '-1').empty();
                        });
                    });
                }
            }
        };
        $.getScript('https://cdn.bootcss.com/mathjax/3.0.5/es5/tex-svg.js');
    }
})