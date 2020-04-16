const hash = str => str.split('').reduce((a, b) => (a * 131 + b.charCodeAt(0))|0, 0).toString(16);

$(function(){
  new Valine({
    el: '#comments',
    appId: 'lrcDpOpEmijtwTFwpnUrPoLO-gzGzoHsz',
    appKey: 'iG7WkFWaL5WUqW1nClpznzmC',
    path: hash(location.pathname),
    pageSize: 10,
    avatar: 'identicon',
    visitor: true,
  });
})