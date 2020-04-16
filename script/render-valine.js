const hash = str => str.split('').reduce((a, b) => (a * 131 + b.charCodeAt(0))|0, 0).toString(16);

$(function(){
  new Valine({
    el: '#comments',
    appId: 'lrcDpOpEmijtwTFwpnUrPoLO-gzGzoHsz',
    appKey: 'iG7WkFWaL5WUqW1nClpznzmC',
    path: hash(location.pathname),
    pageSize: 10,
    avatar: 'identicon',
    placeholder: '写下你的评论……',
    visitor: true,
  });

  // 加载自定义css
  const link = document.createElement("link");
  link.type = "text/css";
  link.rel = "stylesheet";
  link.href = "/stype/comments.css"
  document.getElementsByTagName("head")[0].appendChild(link);
})