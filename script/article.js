function returnTop(){
  $("html,body").stop().animate({scrollTop: 0}, Math.log(document.documentElement.scrollTop) * 100);
}
function onSchSubmit(){
  var value = $(".sch").val();
  if (value == '#test#') {
    location.href = '/tests/';
  } else {
    var url = encodeURI(value);
    if (url != ""){
      url = "https://m.baidu.com/#ie=UTF-8&&wd=" + url;
      $("#subform").attr("src", url).slideDown();
      $("#subform a").attr("href", url);
    } else {
      $("#subform").attr("src", "").slideUp();
    }
  }
}
function rmCookie(name){document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT`;}
function bgcolor(){
  const canvas = document.createElement("canvas");
  const c = canvas.getContext("2d");
  const img = document.getElementById("background");
  c.drawImage(img, 0, 0);
  const imgData = c.getImageData(0, 0, 50, img.clientWidth);
  console.log("P1");
  var r = 0, g = 0, b = 0, n = 1;
  var dr = 0, dg = 0, db = 0;
  for(var i = 0; i < imgData.data.length; i += 4){
    dr = imgData.data[i];
    dg = imgData.data[i+1];
    db = imgData.data[i+2];
    const max = Math.max(dr, dg, db), min = Math.min(dr, dg, db); 
    const l = (max + min) >> 1;
    const s = l < 128 ? (max - min) / (max + min) : (max - min) / (512 - max - min);
    if ((l > 128) && (l < 230) && (s > 0.2)) {
      n += 1;
      r += dr;
      g += dg;
      b += db;
    }  
  }
  if (n < 10) {
    console.log(`P2:${n}`);
    r = 0; g = 0; b = 0; n = 1;
    for(i = 0; i < imgData.data.length; i += 4){
      dr = imgData.data[i],
      dg = imgData.data[i+1],
      db = imgData.data[i+2];
      n += 1;
      r += dr;
      g += dg;
      b += db;
    }
  }
  console.log(n, r, g, b);
  r = (r / n) |0;
  g = (g / n) |0;
  b = (b / n) |0;
  return `rgba(${r},${g},${b},`;
}
var bcolor = str => `rgba(0,0,0,${str})`;
$(function(){
  "use strict";
  const cookies = document.cookie.split(';').map(str => str.split('='));
  const color = cookies.find(arr => arr[0] == 'bcolor');
  if (color) {
    bcolor = str => color[1] + str + ')';
  } else {
    const c = bgcolor();
    document.cookie = `bcolor=${c};`;
    console.log(document.cookie);
    bcolor = str => c + str + ')';
  }
  $("#tagform div").css('background-color', bcolor(1));
  $("#slidebar").css('border-color', bcolor(1));
  // 边栏 Expand
  var b = true;
  var slidebar = $("#slidebar");
  slidebar.slideUp(0);
  $("#menu").click(function(){
    if (b || (document.documentElement.scrollTop > 50)){
      $("#nav").stop().animate({backgroundColor: bcolor(1)}, 500); 
    } else {
      $("#nav").stop().animate({backgroundColor: bcolor(0)}, 500);
    }
    if (b){
      $("#main").stop().animate({marginLeft: "20%", marginTop: (65 - document.documentElement.scrollTop / 20)|0 + "px"}, 500);
      slidebar.stop().animate({opacity: 1}, 200).slideDown(300);
    } else {
      $("#main").stop().animate({marginLeft: "10%", marginTop: "65px"}, 500);
      slidebar.stop().animate({opacity: 0}, 200).slideUp(300);
    }
    b = !b;
  });
  $("#main").click(function(){
    b = true;
    if (document.documentElement.scrollTop > 50) {
      $("#nav").stop().animate({backgroundColor: bcolor(1)}, 500);
      slidebar.stop().animate({opacity: 1},200);
    } else {
      $("#nav").stop().animate({backgroundColor: bcolor(0)}, 500);
      slidebar.stop().animate({opacity: 0},200);
    }
    slidebar.slideUp(300);
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