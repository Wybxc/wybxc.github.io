'''
从知乎上下载文章，保存为 Markdown 格式。
'''

import re
import requests
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36'
}

def escape(s):
    return re.sub(r'[\\`\*_\{\}\[\]\(\)#\+-\.\!]', lambda match: '\\'+ match.group(), s).replace('\\,', ',')

def html2md(node):
    if node is None:
        return ''
    if node.name is None:
        return escape(str(node))
    if node.name == 'p':
        return ''.join((html2md(c) for c in node.children)) + '\n\n'
    if node.name == 'a':
        if node.attrs.get('data-reference-link'):
            index = node.attrs['href'].split('_')[1]
            return f'[^{index}]'
        return f'[{node.text}]({node.attrs["href"]})' + ('\n' if 'LinkCard' in node.attrs['class'] else '')
    if node.name == 'hr':
        return '\n---\n'
    if node.name == 'h2':
        return f'## {node.text}\n'
    if node.name == 'figure':
        return html2md(node.img) + '\n' + html2md(node.figcaption)
    if node.name == 'img':
        if node.attrs.get('eeimg'):
            formula = node.attrs.get('alt')
            return f'$${formula}$$'        
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
    if node.name == 'blockquote':
        content = ''.join((html2md(c) for c in node.children))        
        return  '> ' + '\n> \n> '.join(content.split('\n')) + '\n\n'
    if node.name == 'br':
        return '\n'
    if node.name == 'ol':
        if node.attrs.get('class') and 'ReferenceList' in node.attrs['class']:
            result = ''
            for li in node.children:
                index = li.attrs['id'].split('_')[1]
                result += f"[^{index}]: {escape(li.text).strip('^')}\n"
            return result
        result = ''
        index = 1
        for li in node.children:
            result += f'{index}. {html2md(li)}\n'
            index += 1
        return result
    if node.name == 'ul':
        return '- ' + '\n- '.join((html2md(c) for c in node.children)) + '\n\n'
    if node.name == 'li':
        return ''.join((html2md(c) for c in node.children))
    if node.name == 'span':
        return ''.join((html2md(c) for c in node.children))
    if node.name == 'sup':
        return ''.join((html2md(c) for c in node.children))
    return str(node)


if __name__ == '__main__':
    url = input('请输入网址: ').strip()
    req = requests.get(url, headers=headers)
    req.encoding = 'utf-8'
    soup = BeautifulSoup(req.text, features='lxml')
    title = soup.title.text.strip('- 知乎').strip()    
    markdown = f'''---
layout: default
title: {title}
tags: [知乎文章]
---
'''
    for n in soup.find(class_='RichText'):
        markdown += html2md(n)
    while re.findall(r'\n\n\n', markdown):
        markdown = re.sub(r'\n\n\n', '\n\n', markdown)
    with open(f'./_drafts/{title}.md', 'w', encoding='utf-8') as f:
        f.write(markdown)
