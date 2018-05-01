const bcolor = str => "rgba(187,152,178," + str + ")";
function returnTop(){
  $("html,body").stop().animate({scrollTop: 0}, Math.log(document.documentElement.scrollTop) * 100);
}
function onSchSubmit(){
  let value = $(".sch").val();
  if (value == '#test#') {
    location.href = '/tests/';
  } else {
    let url = encodeURI(value);
    if (url != ""){
      url = "https://m.baidu.com/#ie=UTF-8&&wd=" + url;
      $("#subform").attr("src", url).slideDown();
      $("#subform a").attr("href", url);
    } else {
      $("#subform").attr("src", "").slideUp();
    }
  }
}
$(function(){
  "use strict";
  $("#tagform div").css('background-color', bcolor(1));
  $("#slidebar").css('border-color', bcolor(1));
  // 边栏 Expand
  let b = true;
  let slidebar = $("#slidebar");
  slidebar.slideUp(0);
  $("#menu").click(function(){
    if (b || (document.documentElement.scrollTop > 50)){
      $("#nav").stop().animate({backgroundColor: bcolor(1)}, 500); 
      $("#main").stop().animate({marginLeft: "20%"}, 500);
    } else {
      $("#nav").stop().animate({backgroundColor: bcolor(0)}, 500);
      $("#main").stop().animate({marginLeft: "10%"}, 500);
    }
    if (b){
      slidebar.stop().animate({opacity: 1}, 200).slideDown(300);
    } else {
      slidebar.stop().animate({opacity: 0}, 200).slideUp(300);
    }
    b = !b;
  });
  $("#main").click(function(){
    b = true;
    slidebar.slideUp(500);
    if (document.documentElement.scrollTop > 50) {
      $("#nav").stop().animate({backgroundColor: bcolor(1)}, 500);
      slidebar.stop().animate({opacity: 1},200);
    } else {
      $("#nav").stop().animate({backgroundColor: bcolor(0)}, 500);
      slidebar.stop().animate({opacity: 0},200);
    }
    $("#main").stop().animate({marginLeft: "10%"},500);
    $("#subform").attr("src", "").slideUp();
    $("#subform a").attr("href", "");
  });
  $("#subform").slideUp(0);
  // 搜索
  $(".schbtn").click(onSchSubmit);
  // 导航栏变色
  onscroll = function(){
     if (!b || (document.documentElement.scrollTop > 50)) {
      $("#nav").stop().animate({backgroundColor: bcolor(1)}, 300);
    } else {
      $("#nav").stop().animate({backgroundColor: bcolor(0)}, 300);
    }
  };
  onscroll();
  // 侧栏子菜单
  $("li[index]").mouseenter(function(){
    const index = $(this).attr("index");
    const a = Number(index) - Number($('li[index]').first().attr('index'));
    $("div[index=" + index + "]").stop().css("top", (a * 52 + 60).toString() + "px").show();
    $("#tagform").stop().show();
    $(this).css('background-color', bcolor(0.8));
  });
  $("div[index]").mouseenter(function(){
    $(this).stop().show();
    $("#tagform").stop().show();
    $("li[index=" + $(this).attr("index") + "]").css('background-color', bcolor(0.8));
  });
  $("li[index]").mouseleave(function(){
    $("div[index=" + $(this).attr("index") + "]").hide(1);
    $("#tagform").hide(1);
    $(this).css('background-color', bcolor(0));
  });
  $("div[index]").mouseleave(function(){
    $(this).hide(1); // <- 黑科技
    $("#tagform").hide(1);
    $("li[index=" + $(this).attr("index") + "]").css('background-color', bcolor(0));
  });
  // 最小高度自适应
  onresize = function(){
    $("#main").css('min-height', (document.documentElement.clientHeight - 120) + 'px')
  }
  onresize();
});