$.extend({
  ua: function(){
    var u = navigator.userAgent.toLowerCase();
    var match = null;
    return {
      platform : 
        /\(.*tablet|ipad.*\)/.test(u) ? 'tablet' : 
        /\(.*android|iphone|ipod|iemobile.*\)/.test(u) ? 'mobile' :
        'desktop',
      browser : 
        (match = /msie\s(\d+)/.exec(u)) ? 'ie' :
        (match = /trident\/(\d+)/.exec(u)) ? 'edge' :
        (match = /firefox\/(\d+)/.exec(u)) ? 'firefox' :
        (match = /chrome\/(\d+)/.exec(u)) ? 'chrome' : 'undefined',
      version : parseInt(match[1]) 
    }
  }
});