$("img[src='/tex']").hide();
// 隐藏未加载的公式
$(function(){
  $("img[src='/tex'], img.tex").show();
  // 显示公式
});