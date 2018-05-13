const dot = '&nbsp;\u2022&nbsp;';
const ua = $.ua();
const ablePro = (ua.browser == 'chrome' && ua.version > 60) || (ua.browser == 'firefox' && ua.version > 50);
const wybxcTheme = ablePro ? {
  render: function(state, instance){
    const container = $('<div class="gitment-container gitment-root-container"></div>');
    container.append(instance.renderHeader(state, instance));
    container.append(instance.renderComments(state, instance));
    container.append(instance.renderEditor(state, instance));
    container.append(instance.renderFooter(state, instance));
    container.on('DOMSubtreeModified', function(e){
      const target = $(e.target).find('.gitment-comments-container').get(0);
      if(target)
        var comments = $(target);
      else
        return;
      comments.find('[lang=en-US]').removeAttr('lang');
      comments.find('.gitment-comment-header').each(function(){
        const user = $(this).find('.gitment-comment-name').first();
        const userName = user.text().trim();
        const userLink = user.attr('href');
        const date = $(this).find('span[title]').first();
        const time = new Date(date.attr('title'));
        date.attr('title', time.toLocaleString());
        date.text(`${time.getFullYear()}年${time.getMonth()+1}月${time.getDate()}日`);
        const editDate = date.next().filter('span[title]');
        editDate.each(function(){
          const editTime = new Date($(this).attr('title'));
          $(this).attr('title', editTime.toLocaleString());
          $(this).text(' \u2022 ' + `编辑于${editTime.getFullYear()}年${editTime.getMonth()+1}月${editTime.getDate()}日`);
        });
        const likeBtn = $(this).find('.gitment-comment-like-btn');
        $(this).text('').prepend(
          '<span> 评论于</span>'
        ).prepend(
          $('<a></a>').text(userName).attr({href:userLink, target:'_blank'}).addClass('gitment-comment-name')
        ).append(date).append(editDate).append(likeBtn);
      });
    });
    return container.get(0);
  },
  renderHeader: function(state, instance){
    // 获取信息
    const meta = state.meta,
          user = state.user,
          reactions = state.reactions;
    // 容器
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-header-container';
    // Like Button
    const likedReaction = reactions.find(function (reaction) {
      return reaction.content === 'heart' && reaction.user.login === user.login;
    });
    const likeButton = document.createElement('span');
    likeButton.className = 'gitment-header-like-btn';
    likeButton.innerHTML = '&nbsp;' + (likedReaction ? '取消感谢' : '感谢');
    $(likeButton).prepend('<span class="fa fa fa-heart-o"></span>');
    if (likedReaction) {
      likeButton.classList.add('liked');
      likeButton.onclick = () => instance.unlike();
    } else {
      likeButton.classList.remove('liked');
      likeButton.onclick = () => instance.like();
    }
    container.appendChild(likeButton);
    (meta.reactions && meta.reactions.heart) ?
      ($(container).append(dot + `<strong>${meta.reactions.heart}</strong>人感谢过`)):void(0);
    // Comments Count
    meta.comments ?
      ($(container).append(dot + `<span>${meta.comments}条评论</span>`)) : void(0);
    // Issue Page
    const issueLink = `<a class="gitment-header-issue-link" href="${meta.html_url}" target="_blank">Issue 页面</a>`;
    $(container).append(issueLink);
    // return
    return container;
  },
  renderFooter: function(state, instance){
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-footer-container';
    container.innerHTML = 'Powered by <a class="gitment-footer-project-link" href="https://github.com/imsun/gitment" target="_blank">Gitment</a> <a class="fa fa-github" style="font-size: 1.5em;" href="https://github.com" target="_blank"></a>';
    return container;
  }
} : {
  render: function(state, instance){
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-root-container';
    container.appendChild(instance.renderComments(state, instance));
    $(container).append(`<p>评论请前往对应的&nbsp;<a href="${state.meta.html_url}" target="_blank">Issue&nbsp;页<a>。<p>`);
    container.appendChild(instance.renderFooter(state, instance));
    return container;
  }
};

const hash = str => str.split('').reduce((a, b) => (a * 131 + b.charCodeAt(0))|0, 0).toString(16);
const gitment = new Gitment({
  id: hash(location.origin + location.pathname),
  owner: 'Wybxc',
  repo: 'wybxc.github.io',
  oauth: {
    client_id: 'e1e459175a9ddeb47646',
    client_secret: '9dc3d932e62f88b62e3b6de096de4b74c77f97b2',
  },
  perPage: 10,
  theme: wybxcTheme
});
$(function(){
  gitment.render('comments');
});