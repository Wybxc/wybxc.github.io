---
layout: index
title: 忘忧北萱草的小博客
---

> 美人愁思兮，采芙蓉于南浦。
>
> 公子忘忧兮，树萱草于北堂。

<a href="https://github.com/Wybxc/wybxc.github.io" target="_blank" style="text-decoration: none">忘忧北萱草</a>，一直追逐与学习，只为实现一句话：**厚积而薄发**。

---

{%- capture tagstr %}
  {%- for post in site.posts %}
    {%- assign tags = post.tags | join: ' ' %}
    {%- unless tags contains '测试' or tags contains '隐藏' %}
      {%- for tag in post.tags %}
        {{ tag }}
      {%- endfor %}
    {%- endunless %}
  {%- endfor %}
{%- endcapture %}
{%- assign tags = tagstr | normalize_whitespace | split: ' ' | uniq | sort %}
{%- assign excludes = '测试 隐藏 ' | split: ' ' | uniq | sort%}

{% include summary.html tags = tags excludes = excludes %}

