(function (global, doc) {
    function getDOMElement(node) {
        if (typeof node === "string") {
            node = doc.querySelector(node);
            if (node === null)
                throw "Element not found!";
        }
        if (node instanceof global.HTMLElement)
            return node;
        else
            throw "Not an element!";
    }

    function ajaxGetJSON(url) {
        return new Promise(function (resolve, reject) {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState == 4) {
                    if (xhr.status == 200 || xhr.status == 304) {
                        const jsonObj = JSON.parse(xhr.responseText);
                        console.log(jsonObj);
                        resolve(jsonObj);
                    } else {
                        reject('HTTP ' + xhr.status + ' error!');
                    }
                }
            };
            xhr.send();
        });
    }

    function loadJSON(json) {
        if (Array.isArray(json))
            return Promise.resolve(json);
        if (typeof json === "string")
            return ajaxGetJSON(json);
    }

    function format(template, obj, middleware) {
        if (!template.replace) throw "Argument must be string!";
        return template.replace(/\{\w+?\}/g, match => middleware(obj, match.slice(1, -1)));
    }

    function defaultTemplateMiddleware(obj, field) {
        return obj[field];
    }

    function defaultSegmenter(str) {
        str = str.trim()
        if (str.length == 0) return Promise.resolve([]); 
        if (str.length == 1) return Promise.resolve([str]); 
        const url = `//bird.ioliu.cn/v1?url=http://api.pullword.com/get.php&source=${encodeURI(str)}&param1=0&param2=0&json=1`
        return ajaxGetJSON(url).then(json => json.map(word => word.t));
    }

    function defaultMatch(keywords, page) {
        let score = 0;

        const title = ('' + page.title).toUpperCase();
        const category = ('' + page.category).toUpperCase();
        const tags = ('' + page.tags).toUpperCase();
        const content = ('' + page.content).toUpperCase();

        keywords.map(keyword => keyword.toUpperCase()).forEach(keyword => {
            score += title.includes(keyword) ? 3 : 0;
            score += category.includes(keyword) ? 2 : 0;
            score += tags.includes(keyword) ? 2 : 0;
            score += content.includes(keyword) ? 1 : 0;
        });

        return score;
    }

    class TidSearch {
        constructor(config) {
            this.input = config.input ? getDOMElement(config.input) : null;
            this.output = getDOMElement(config.output);
            this.json = null;
            this.template = config.template || '<p><a href="{url}">{title}</a></p>';
            this.templateMiddleware = config.templateMiddleware || defaultTemplateMiddleware;
            this.noResult = config.noResult || 'No Result.';
            this.segmenter = config.segmenter || defaultSegmenter;
            this.match = config.match || defaultMatch;
            this.paginator = config.paginator;
            this.afterSearch = config.afterSearch;

            this.loaded = loadJSON(config.json).then(result => {
                this.json = result;
            }, reason => {
                throw "Load JSON fail! " + reason;
            }).then(() => {
                let register = null;
                if (!this.input.addEventListener)
                    if (this.input.attachEvent)
                        register = func => this.input.attachEvent('onpropertychange', func);
                    else throw "Your Browser is too old!";
                register = func => {
                    this.input.addEventListener('input', func);
                    this.input.addEventListener('paste', func);
                };
                register(() => this.search(this.input.value));
            });
        }

        search(str) {
            if (!this.json) {
                const errMsg = "Please wait till JSON Loaded.";
                console.warn(errMsg);
                return Promise.reject(errMsg);
            }
            return this.segmenter(str).then(keywords => {
                if (!keywords.length) {
                    this.output.innerHTML = '';
                    return [];
                }
                let pages = this.json.map(page => ({
                    score: this.match(keywords, page),
                    page: page,
                })).filter(a => a.score > 0);
                pages = pages.sort((a, b) => b.score - a.score).map(a => a.page);
                if (!pages.length)
                    this.output.innerHTML = this.noResult;
                else {
                    const pageElements = pages.map(page => format(this.template, page, this.templateMiddleware));
                    if (this.paginator) {
                        throw "Unimplemented";
                        this.paginator(pageElements).map(pages => pages.join('\n'));
                    } else {
                        this.output.innerHTML = pageElements.join('\n');
                    }
                }
                return pages;
            }).then(result => {
                if(this.afterSearch) this.afterSearch(result);
                return result;
            });            
        }
    }

    global.TidSearch = TidSearch;
})(window, document);
