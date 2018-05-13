const ua = $.ua();
const ablePro = (ua.browser == 'chrome' && ua.version > 60) || (ua.browser == 'firefox' && ua.version > 50);
const wybxcTheme = ablePro ? {
  render: function(state, instance){
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-root-container';
    container.appendChild(instance.renderHeader(state, instance));
    container.appendChild(instance.renderComments(state, instance));
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
  renderComments: function(state, instance){
    const meta = state.meta,
          comments = state.comments,
          commentReactions = state.commentReactions,
          currentPage = state.currentPage,
          user = state.user,
          error = state.error;
    // 容器
    const container = document.createElement('div');
    container.className = 'gitment-container gitment-header-container';
    // Error
    if (error) {
      var errorBlock = document.createElement('div');
      errorBlock.className = 'gitment-comments-error';
      if (error === _constants.NOT_INITIALIZED_ERROR && user.login && user.login.toLowerCase() === instance.owner.toLowerCase()) {
        var initHint = document.createElement('div');
        var initButton = document.createElement('button');
        initButton.className = 'gitment-comments-init-btn';
        initButton.onclick = function () {
          initButton.setAttribute('disabled', true);
          instance.init().catch(function (e) {
            initButton.removeAttribute('disabled');
            alert(e);
          });
        };
        initButton.innerText = '初始化评论';
        initHint.appendChild(initButton);
        errorBlock.appendChild(initHint);
      } else {
        errorBlock.innerText = error;
      }
      container.appendChild(errorBlock);
      return container;
    } else if (comments === undefined) {
      var loading = document.createElement('div');
      loading.innerText = '加载评论中';
      $(loading).append('<span class="fa fa-spinner fa-spin"></span>');
      loading.className = 'gitment-comments-loading';
      container.appendChild(loading);
      return container;
    } else if (!comments.length) {
      var emptyBlock = document.createElement('div');
      emptyBlock.className = 'gitment-comments-empty';
      emptyBlock.innerText = 'No Comment Yet';
      container.appendChild(emptyBlock);
      return container;
    }
    // Comments
    var commentsList = document.createElement('ul');
    commentsList.className = 'gitment-comments-list';
    comments.forEach(function (comment) {
      var createDate = new Date(comment.created_at);
      var updateDate = new Date(comment.updated_at);
      var commentItem = document.createElement('li');
      commentItem.className = 'gitment-comment';
      $(commentItem).append(`<a class="gitment-comment-avatar" href="${comment.user.html_url}" target="_blank"></a>`)
        .append(`<img class="gitment-comment-avatar-img" src="${comment.user.avatar_url}"/>`)
        .append($('<div class="gitment-comment-main"></div>')
          .append($('<div class="gitment-comment-header"></div>')
            .append(`<a class="gitment-comment-name" href="${comment.user.html_url}" target="_blank">${comment.user.login}</a>评论于<span title="${createDate}">${createDate.toDateString()}</span>`)
            .append(createDate.toString() !== updateDate.toString() ? dot + `<span title="comment was edited at ${updateDate}">edited</span>` : '')
            .append(`<div class="gitment-comment-like-btn"><span class="fa fa-spinner fa-spin"></span>${comment.reactions.heart || ''}</div>`))
          .append(`<div class="gitment-comment-body gitment-markdown">${comment.body_html}</div>`));        
      var likeButton = commentItem.querySelector('.gitment-comment-like-btn');
      var likedReaction = commentReactions[comment.id] && commentReactions[comment.id].find(function (reaction) {
        return reaction.content === 'heart' && reaction.user.login === user.login;
      });
      if (likedReaction) {
        likeButton.classList.add('liked');
        likeButton.onclick = () => instance.unlikeAComment(comment.id);
      } else {
        likeButton.classList.remove('liked');
        likeButton.onclick = () => instance.likeAComment(comment.id);
      }
      // dirty
      // use a blank image to trigger height calculating when element rendered
      var imgTrigger = document.createElement('img');
      var markdownBody = commentItem.querySelector('.gitment-comment-body');
      imgTrigger.className = 'gitment-hidden';
      imgTrigger.src = "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";
      imgTrigger.onload = function () {
        if (markdownBody.clientHeight > instance.maxCommentHeight) {
          markdownBody.classList.add('gitment-comment-body-folded');
          markdownBody.style.maxHeight = instance.maxCommentHeight + 'px';
          markdownBody.title = '点击以展开';
          markdownBody.onclick = function () {
            markdownBody.classList.remove('gitment-comment-body-folded');
            markdownBody.style.maxHeight = '';
            markdownBody.title = '';
            markdownBody.onclick = null;
          };
        }
      };
      commentItem.appendChild(imgTrigger);
      commentsList.appendChild(commentItem);
    });
    container.appendChild(commentsList);
    if (meta) {
      var pageCount = Math.ceil(meta.comments / instance.perPage);
      if (pageCount > 1) {
        var pagination = document.createElement('ul');
        pagination.className = 'gitment-comments-pagination';
        if (currentPage > 1) {
          var previousButton = document.createElement('li');
          previousButton.className = 'gitment-comments-page-item';
          previousButton.innerText = '上一页';
          previousButton.onclick = function () {
            return instance.goto(currentPage - 1);
          };
          pagination.appendChild(previousButton);
        }
        var _loop = function _loop(i) {
          var pageItem = document.createElement('li');
          pageItem.className = 'gitment-comments-page-item';
          pageItem.innerText = i;
          pageItem.onclick = function () {
            return instance.goto(i);
          };
          if (currentPage === i) pageItem.classList.add('gitment-selected');
          pagination.appendChild(pageItem);
        };
        for (var i = 1; i <= pageCount; i++) {
          _loop(i);
        }
        if (currentPage < pageCount) {
          var nextButton = document.createElement('li');
          nextButton.className = 'gitment-comments-page-item';
          nextButton.innerText = '下一页';
          nextButton.onclick = function () {
            return instance.goto(currentPage + 1);
          };
          pagination.appendChild(nextButton);
        }
        container.appendChild(pagination);
      }
    }
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