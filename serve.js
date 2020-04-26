const Promise = require('bluebird');
const fs = Promise.promisifyAll(require('fs'));
const path = require("path");
const watch = require('node-watch');
const exec = require("child_process").exec;
const babel = require("@babel/core");
const UglifyJS = require("uglify-js");
const yaml = require("js-yaml");
const handler = require('serve-handler');
const http = require('http');

const fileWatchers = [];

// 编译js文件

function compile(filename, out) {
    filename = path.normalize(filename);
    out = path.normalize(out);
    console.log('Compile ' + filename);
    return babel.transformFileAsync(filename, { code: true }).then(result => {
        const ug = UglifyJS.minify(result.code, {
            warnings: true
        });
        if (ug.error) console.log(filename + ' :'), console.log(ug.error);        
        return ug.code;        
    }).then(code =>
        fs.writeFileAsync(out, code)
    );
}

function remove(filename) {
    return fs.unlinkAsync(filename);
}

// 编译jekyll

function jekyllBuild(filename) {
    console.log('\n');
    if (filename)
        console.log(filename + " changed, rebuilding Site...");
    exec("jekyll build", (_error, stdout, stderr) => {
        console.log(stdout);
        console.log(stderr);
    });
}

const scriptInputFolder = './script/es6/';
const scriptOutputFolder = './script/';

const excluded = ['.', '_site', 'serve.js', 'package.json'];

fileWatchers.push(watch(scriptInputFolder, (event, filename) => {
    filename = path.normalize(filename);
    const basename = path.basename(filename);
    if (event === 'update')
        compile(filename, scriptOutputFolder + basename);
    else
        remove(scriptOutputFolder + basename);
}));

fs.readdirAsync(scriptInputFolder).then(files => {
    const firstCompilePromises = files.map(file => compile(scriptInputFolder + file, scriptOutputFolder + file));
    Promise.all(firstCompilePromises).then(() => {
        jekyllBuild();
        return fs.readFileAsync('_config.yml').then(data => yaml.safeLoad(data))
            .then(config => config.exclude.concat(excluded).map(p => path.normalize(p))).then(exclude => {
                fileWatchers.push(watch('.', {
                    recursive: true,
                    filter: filename => exclude.every(ex => !path.normalize(filename).startsWith(ex))
                }, (_event, filename) => jekyllBuild(filename)));
            });
    });
});


const server = http.createServer((request, response) => {
    return handler(request, response, { public: "_site" });
})

server.listen(4000, () => {
    console.log('Running at http://localhost:4000');
    console.log('Press Ctrl+C to stop.');
});


process.on('unhandledRejection', error => {
    console.log(error);
});

process.on('SIGINT', () => {
    console.log('Exit.');
    fileWatchers.forEach(watcher => watcher.close());
    process.exit();
});