---
layout: default
title: LexBurner粉丝数实时查看
tags: [杂项,隐藏]
---

当前粉丝数：
<p id="follower"></p>
<script>
    function ajaxGetJSON(url) {
        return new Promise(function (resolve, reject) {
            const xhr = window.XMLHttpRequest ?
                new window.XMLHttpRequest() :
                new gloabl.ActiveXObject('Microsoft.XMLHTTP');
            xhr.open('GET', url, true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState == 4) {
                    if (xhr.status == 200 || xhr.status == 304) {
                        const jsonObj = JSON.parse(xhr.responseText);
                        resolve(jsonObj);
                    } else {
                        reject('HTTP ' + xhr.status + ' error!');
                    }
                }
            };
            xhr.send();
        });
    }
    setInterval(function(){
        ajaxGetJSON("//bird.ioliu.cn/v1?url=https://api.bilibili.com/x/relation/stat?vmid=777536").then(function(json){
            $("p#follower").text(json.data.follower);
        });
    },1000);
</script>