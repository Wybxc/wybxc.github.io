$('body').ready(function () {
    const $mask = $('#mask');
    let shown = false;
    function showMask() {
        if (shown) return;
        $mask.css({
            'background-color': 'white',
            'opacity': '0',
            'z-index': '60',
            'mix-blend-mode': 'normal',
        }).animate({ opacity: '0.75' }, 250).append('<div style="position: relative;top: 40%;margin: 0 auto;">' +
            '<i class="fa fa-spinner fa-pulse fa-3x fa-fw"></i>' +
            '<p>加载 Mathjax 中……</p>' +
            '</div>');
        shown = true;
    }

    function hideMask() {
        if (!shown) return;
        $mask.animate({ opacity: '0' }, 300, function () {
            $mask.css('z-index', '-2').empty();
        });
        shown = false;
    }

    function strip(s) {
        return s.replace("% <![CDATA[", '').replace("%]]>", '')
            .replace(/[<>&"]/g, c => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;' })[c]).trim();
    }

    $("script[type='math/tex']").replaceWith(function () {
        const tex = $(this).html();
        return '$$' + strip(tex) + '$$';
    });

    $("script[type='math/tex; mode=display']").replaceWith(function () {
        const tex = $(this).html();
        return '<p>\\[' + strip(tex) + '\\]</p>';
    });

    const hasEquation = /(\$\$.*\$\$)|(\\\[.*\]\\)/.test($('#main').text());
    if (hasEquation) {
        showMask();
        setTimeout(hideMask, 10000);
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
                    MathJax.startup.promise.then(hideMask);
                }
            }
        };
        $.getScript('https://cdn.bootcss.com/mathjax/3.0.5/es5/tex-chtml.js');
    }
})