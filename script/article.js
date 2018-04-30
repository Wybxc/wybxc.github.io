function returnTop(){
  $("html,body").animate({scrollTop: 0}, Math.log(document.documentElement.scrollTop) * 100);
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
  // 边栏 Expand
  let slidebar = $("#slidebar");
  slidebar.slideUp(0);
  $("#menu").click(function(){
    slidebar.slideToggle();
  });
  $("#main").click(function(){
    slidebar.slideUp();
    $("#subform").attr("src", "").slideUp();
  });
  $("#subform").slideUp(0);
  // 搜索
  $(".schbtn").click(onSchSubmit);
  // 导航栏变色
  onscroll = function(){
    if (document.documentElement.scrollTop > 50) {
      $("#nav").stop().animate({backgroundColor: "rgba(187,152,178,1)"}, 300);
      $("#slidebar").stop().animate({backgroundColor: "rgba(187,152,178,0.5)"}, 300);
    } else {
      $("#nav").stop().animate({backgroundColor: "rgba(128,128,128,0)"}, 300);
      $("#slidebar").stop().animate({backgroundColor: "rgba(187,152,178,0)"}, 300);
    }
  };
  onscroll();
  // 侧栏子菜单
  $("li[index]").mouseenter(function(){
    const index = $(this).attr("index");
    const a = Number(index) - Number($('li[index]').first().attr('index'));
    $("div[index=" + index + "]").stop().css("top", (a * 52 + 65).toString() + "px").show();
    $("#tagform").stop().show();
    $(this).css('background-color', "rgba(187,152,178,0.8");
  });
  $("div[index]").mouseenter(function(){
    $(this).stop().show();
    $("#tagform").stop().show();
    $("li[index=" + $(this).attr("index") + "]").css('background-color', "rgba(187,152,178,0.8");
  });
  $("li[index]").mouseleave(function(){
    $("div[index=" + $(this).attr("index") + "]").hide(1);
    $("#tagform").hide(1);
    $(this).css('background-color', "rgba(187,152,178,0");
  });
  $("div[index]").mouseleave(function(){
    $(this).hide(1); // <- 黑科技
    $("#tagform").hide(1);
    $("li[index=" + $(this).attr("index") + "]").css('background-color', "rgba(187,152,178,0");
  });
});