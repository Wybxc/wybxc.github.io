function getScrollY() {
    return window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
}

function returnTop() {
    const scrollY = getScrollY();
    if (scrollY > 0)
        $("html,body").stop().animate({ scrollTop: 0 }, Math.log(scrollY) * 100);
}

function jumpto(url) {
    window.top.window.location = url; // window.location.href 在某些浏览器上不能正常跳转
}

function onSchSubmit() {
    const value = $(".sch").val();
    let url = encodeURI(value);
    if (url != "") {
        url = "/search#" + url;
        $("#subform").attr("src", url).slideDown();
        $("#subform a").attr("href", url);
    } else {
        $("#subform").attr("src", "").slideUp();
    }
}

function rmCookie(name) {
    document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
}

function bgcolor() {
    try {
        const canvas = document.createElement("canvas");
        const c = canvas.getContext("2d");
        const img = document.getElementById("background");
        c.drawImage(img, 0, 0);
        const imgData = c.getImageData(0, 0, 50, img.clientWidth).data;
        let r = 0, g = 0, b = 0, n = 0;
        let validColor = (r, g, b) => {
            const max = Math.max(r, g, b), min = Math.min(r, g, b);
            const l = (max + min) >> 1;
            const s = (l < 128) ? ((max - min) / (max + min)) : ((max - min) / (512 - max - min));
            return l > 128 && l < 230 && s > 0.2;
        };
        while (n < 10) {
            n = 0;
            for (let i = 0; i < imgData.length; i += 4) {
                let dr = imgData[i], dg = imgData[i + 1], db = imgData[i + 2];
                if (validColor(dr, dg, db)) {
                    n += 1;
                    r += dr;
                    g += dg;
                    b += db;
                }
            }
            validColor = (_r, _g, _b) => true;
        }
        r = (r / n) | 0;
        g = (g / n) | 0;
        b = (b / n) | 0;
        if (r * g * b == 0) {
            return 'rgba(187,152,178,';
        }
        return `rgba(${r},${g},${b},`;
    } catch (e) {
        console.log(e);
        return 'rgba(187,152,178,';
    }
}

function getBackgroundColor() {
    let bcolor = str => `rgba(0,0,0,${str})`;
    const cookies = document.cookie.split(';').map(str => str.split('='));
    const color = cookies.find(arr => arr[0] == 'bcolor');
    if (color) {
        bcolor = str => color[1] + str + ')';
    } else {
        const c = bgcolor();
        document.cookie = `bcolor=${c};`;
        bcolor = str => c + str + ')';
    }
    return bcolor;
}

// 桌面版
if (window.screen.width >= 800) {
    $(function () {
        "use strict";
        let bcolor = getBackgroundColor();
        $("#tagform div").css('background-color', bcolor(1));
        $("#slidebar").css('border-color', bcolor(1));

        // 边栏 Expand
        let notExpanded = true;
        const $slidebar = $("#slidebar");
        const $nav = $("#nav");
        const $main = $("#main");
        $slidebar.slideUp(0);
        $("#menu").click(function () {
            if (notExpanded || getScrollY() > 50) {
                $nav.stop().animate({ backgroundColor: bcolor(1) }, 500);
            } else {
                $nav.stop().animate({ backgroundColor: bcolor(0) }, 500);
            }
            if (notExpanded) {
                $main.stop().animate({ marginLeft: "30%" }, 500);
                $slidebar.stop().animate({ opacity: 1 }, 200).slideDown(300);
            } else {
                $main.stop().animate({ marginLeft: "20%" }, 500);
                $slidebar.stop().animate({ opacity: 0 }, 200).slideUp(300);
            }
            notExpanded = !notExpanded;
        });
        $main.click(function () {
            notExpanded = true;
            if (getScrollY() > 50) {
                $nav.stop().animate({ backgroundColor: bcolor(1) }, 500);
                $slidebar.stop().animate({ opacity: 0 }, 200);
            } else {
                $nav.stop().animate({ backgroundColor: bcolor(0) }, 500);
                $slidebar.stop().animate({ opacity: 0 }, 200);
            }
            $slidebar.slideUp(300);
            $main.stop().animate({ marginLeft: "20%" }, 500);
            $("#subform").attr("src", "").slideUp();
            $("#subform a").attr("href", "");
        });
        $("#subform").slideUp(0);

        // 搜索
        $(".schbtn").click(onSchSubmit);

        // 导航栏变色
        window.onscroll = function () {
            if (!notExpanded || getScrollY() > 50) {
                $nav.stop().animate({ backgroundColor: bcolor(1) }, 300);
            } else {
                $nav.stop().animate({ backgroundColor: bcolor(0) }, 300);
            }
        };
        window.onscroll();

        // 侧栏子菜单
        const $tagform = $("#tagform");
        $("li[data-index]").mouseenter(function () {
            const index = $(this).attr("data-index");
            const a = Number(index) - Number($('li[data-index]').first().attr('data-index'));
            $("div[data-index=" + index + "]").stop().css("top", (a * 52 + 60).toString() + "px").show();
            $tagform.stop().show();
            $(this).css('background-color', bcolor(0.8));
        });
        $("div[data-index]").mouseenter(function () {
            $(this).stop().show();
            $tagform.stop().show();
            $("li[data-index=" + $(this).attr("data-index") + "]").css('background-color', bcolor(0.8));
        });
        $("li[data-index]").mouseleave(function () {
            $("div[data-index=" + $(this).attr("data-index") + "]").hide(1);
            $tagform.hide(1);
            $(this).css('background-color', bcolor(0));
        });
        $("div[data-index]").mouseleave(function () {
            $(this).hide(1); // <- 黑科技
            $tagform.hide(1);
            $("li[data-index=" + $(this).attr("data-index") + "]").css('background-color', bcolor(0));
        });
    });

} else { // 移动版
    $(function () {
        "use strict";
        const defaultColor = getBackgroundColor()(1);
        $("#nav").css('background-color', defaultColor);
        $("ul.taglist li, #tagform li").css("border-color", defaultColor);

        // 左边栏展开 & 侧栏子菜单
        let notExpanded = true;
        let animateTime = 150;
        let $mask = $("#mask");
        let $tagform = $("#tagform");
        let $slidebar = $("#slidebar");
        function hideTag(tag) {
            $("div[data-index=" + $(tag).attr("data-index") + "]").hide(1);
            $(tag).css('background-color', "white");
        }
        let currentTag = $("li[data-index]").first()[0];
        $("#menu").click(function () {
            if (notExpanded) {
                $mask.css({ "z-index": "10", "opacity": "1", "mix-blend-mode": "darken" });
                $mask.stop().animate({ backgroundColor: "rgb(128,128,128,0.8)" });
                $tagform.stop().show().css({ "left": "-20%", "right": "40%", "opacity": "0" });
                $(currentTag).click();
                $slidebar.stop().animate({ left: '0', right: '60%' }, animateTime, function () {
                    $tagform.animate({ left: '40%', right: '0', opacity: '1' }, animateTime);
                });
            } else {
                $mask.css({ "z-index": "-2", "opacity": "1", "mix-blend-mode": "darken" });
                $mask.stop().animate({ backgroundColor: "rgb(128,128,128,0)" });
                $tagform.stop().css({ "left": "40%", "right": "0", "opacity": "1" });
                $slidebar.stop();
                $tagform.animate({ left: '-20%', right: '60%', opacity: 0 }, animateTime, function () {
                    $slidebar.animate({ left: '-40%', right: '100%' }, animateTime, function () {
                        hideTag(currentTag);
                    });
                    $tagform.hide();
                })
            }
            notExpanded = !notExpanded;
        });
        $("li[data-index]").click(function () {
            if (currentTag != this) hideTag(currentTag);
            currentTag = this;
            $("div[data-index=" + $(this).attr("data-index") + "]").stop().show();
            $(this).css('background-color', defaultColor);
        });
    });
}

$(function () {
    // 最小高度自适应
    onresize = function () {
        $("#main").css('min-height', (document.documentElement.clientHeight - 120) + 'px')
    }
    onresize();
    // 脚注图标
    $("a.reversefootnote").css('text-decoration', 'none').attr('class', 'fa fa-reply').empty();
});