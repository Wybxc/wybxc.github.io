const ua = $.ua();
const ablePro = (ua.browser == 'chrome' && ua.version > 60) || (ua.browser == 'firefox' && ua.version > 50);
const wybxcTheme = ablePro ? {
  render: function(state, instance){
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-root-container';
    container.appendChild(instance.renderHeader(state, instance));
    const comments = instance.renderComments(state, instance);
    $(comments).find('[lang=en-US]').removeAttr('lang');
    $(comments).find('.gitment-comment-header').each(function(){
      const user = $(this).find('.gitment-comment-name').first();
      const userName = user.text();
      const userLink = user.attr('href');
      user.remove();
      const date = $(this).find('span[title]').first()
      const time = new Date(date.attr('title'));
      date.attr('title', time.toLocaleString());
      date.text(`${time.getFullYear()}年${time.getMonth()+1}月${time.getDate()}日`);
      $(this).text('').prepend(
        '<span>评论于</span>'
      ).prepend(
        $('<a></a>').text(userName).attr({href:userLink, target:'_blank'}).addClass('gitment-comment-name')
      );
      const editDate = date.next().filter('span[title]');
      editDate.each(function(){
        const editTime = new Date($(this).attr('title'));
        $(this).attr('title', editTime.toLocaleString());
      });
    });
    container.appendChild(comments);
    container.appendChild(instance.renderEditor(state, instance));
    container.appendChild(instance.renderFooter(state, instance));
    return container;
  },
  renderHeader: function(state, instance){
    // 获取信息
    const meta = state.meta,
          user = state.user,
          reactions = state.reactions;
    const dot = '\u2022';
    // 容器
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-header-container';
    // Like Button
    const likedReaction = reactions.find(function (reaction) {
      return reaction.content === 'heart' && reaction.user.login === user.login;
    });
    const likeButton = document.createElement('span');
    likeButton.className = 'gitment-header-like-btn';
    likeButton.innerHTML = (likedReaction ? '取消感谢' : '感谢');
    (meta.reactions && meta.reactions.heart) ?
      (likeButton.append(dot + `<strong>${meta.reactions.heart}</strong>人感谢过`)):void(0);
    $(likeButton).prepend('<span class="fa fa fa-heart-o"></span>');
    if (likedReaction) {
      likeButton.classList.add('liked');
      likeButton.onclick = () => instance.unlike();
    } else {
      likeButton.classList.remove('liked');
      likeButton.onclick = () => instance.like();
    }
    container.appendChild(likeButton);
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
    container.innerHTML = 'Powered by<a class="gitment-footer-project-link" href="https://github.com/imsun/gitment" target="_blank">Gitment</a><a class="fa fa-github" href="https://github.com" target="_blank"></a>';
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
$(function(){gitment.render('comments');});