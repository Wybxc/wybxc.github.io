'''
从知乎上下载文章，保存为 Markdown 格式。
'''

import requests
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36'
}


def html2md(node):
    if node is None:
        return ''
    if node.name is None:
        return str(node)
    if node.name == 'p':
        return ''.join((html2md(c) for c in node.children)) + '\n\n'
    if node.name == 'a':
        return f'[{node.text}]({node.attrs["href"]})' + ('\n' if 'LinkCard' in node.attrs['class'] else '')
    if node.name == 'hr':
        return '\n---\n'
    if node.name == 'h2':
        return f'## {node.text}\n'
    if node.name == 'figure':
        return html2md(node.img) + '\n' + html2md(node.figcaption)
    if node.name == 'img':
        src = node.attrs['src']
        name = src.split('/')[-1]
        with open(f'./res/{name}', 'wb') as img:
            img.write(requests.get(src, headers=headers, stream=True).content)
        return f'![l:{name}](/res/{name})'
    if node.name == 'figcaption':
        return f'*{node.text}*\n'
    if node.name == 'b':
        return f"**{''.join((html2md(c) for c in node.children))}**"
    if node.name == 'i':
        return f"*{''.join((html2md(c) for c in node.children))}*"
    if node.name == 'div':
        return ''.join((html2md(c) for c in node.children)) + '\n\n'
    if node.name == 'pre':
        return '{% highlight ' + node.code.attrs['class'][0].split('-')[-1] + ' %}\n' + node.code.text + '\n{% endhighlight %}\n'
    if node.name == 'code':
        return f'`{node.text}`'
    return str(node)


if __name__ == '__main__':
    url = input('请输入网址: ').strip()
    req = requests.get(url, headers=headers)
    req.encoding = 'utf-8'
    soup = BeautifulSoup(req.text, features='lxml')
    with open(f'./_drafts/{soup.title.text}.md', 'w', encoding='utf-8') as f:
        for node in soup.find(class_='RichText'):
            f.write(html2md(node))
