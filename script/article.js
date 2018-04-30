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
  $(".schbtn").click(onSchSubmit);
});