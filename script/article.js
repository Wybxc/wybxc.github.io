function onSchSubmit(){
    let url = encodeURI($(".sch").val());
    if (url != ""){
      // window.open("https://www.baidu.com/#ie=UTF-8&&wd=" + url);
      url = "https://m.baidu.com/#ie=UTF-8&&wd=" + url;
      $("#subform").attr("src", url).slideDown();
      $("#subform a").attr("src", url);
    }else{
      $("#subform").attr("src", "").slideUp();
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
  $("pre.hightlight").removeClass("hightlight");
});