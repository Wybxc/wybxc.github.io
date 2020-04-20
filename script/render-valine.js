const hash = str => str.split('').reduce((a, b) => (a * 131 + b.charCodeAt(0))|0, 0).toString(16);

$(function(){
  valine = new Valine();
  valine.init({
    el: '#comments',
    appId: 'lrcDpOpEmijtwTFwpnUrPoLO-gzGzoHsz',
    appKey: 'iG7WkFWaL5WUqW1nClpznzmC',
    path: hash(location.pathname),
    pageSize: 10,
    avatar: 'identicon',
    placeholder: '写下你的评论……',
  });
  intervalID = setInterval(function(){
    const selected = $('.v svg');
    if (selected.length != 0) {
      console.log(selected);
      clearInterval(intervalID);
      selected.attr("width", "40");
      selected.attr("height", "40");
    }
  }, 100);
})