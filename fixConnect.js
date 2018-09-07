let transformer = require('react-native-typescript-transformer');

var findClassExports =/^export +([A-Za-z0-9]+)? ?class +([A-Z][A-Za-z0-9]+)/m;
var pathReg = /(\/|\\)containers|components(\/|\\).*\.tsx$/;
var componentsReg = /(\/|\\)components(\/|\\).*\.tsx$/;
var findStatement = /^export +class +_([A-Za-z0-9]+) +extends +\1 ?{}/m;
var hasClass = /class/m;
function tshot(str,filename) {
    if(pathReg.test(filename)){
        var map = {}
        while(true){
            if(findStatement.test(str) || findClassExports.test(str)){
                if(findClassExports.test(str)){
                    str = str.replace(findClassExports,function(s,s1,s2){
                        map[s1 || s2] = s2;
                        if(s1){
                            return `class ${s2}`
                        } else {
                            return `class ${s2}_`
                        }
                    })
                }
                if(findStatement.test(str)){
                    str = str.replace(findStatement,function(s,s1){
                        var s2="";
                        Object.prototype.hasOwnProperty.call(map,s1) && ( s2 = s1 + "_" );
                        return `export class _${s1} extends ${s2 || s1} {componentWillMount = ()=> console.error('class "_${s1}" can only be used when the statement')}`
                    });
                }
            }else {
                break;
            }
        };
        if(Object.keys(map).length){
            str += '\nlet _gp_ = (cls,key) => Object.prototype.hasOwnProperty.call(cls,key) ? cls[key] : null ;'
        } else {
            if(hasClass.test(str)){
                console.log("warning: not export any class,",filename)
            }
        }
        function exportFn(exportKey,k,cls) {

return str += `
let export_${k};
if(_gp_(${cls},'mapStateToProps') || _gp_(${cls},'mapDispatchToProps')){
    export_${k} = reduxConnect(${cls},_gp_(${cls},'mapStateToProps'),_gp_(${cls},'mapDispatchToProps'));
} else {
    export_${k} = ${cls};
}
export ${exportKey} export_${k};
`;
        }

        for(var k of Object.keys(map)){
            if(k == "default"){
                exportFn(k,k,map[k])
            } else {
                exportFn(`const ${k} =`,k,map[k]+"_")
            }
        }
    }
    return str;
};

module.exports.transform = function(src, filename, options) {
    if (typeof src === 'object') {
      ;({ src, filename, options } = src)
    }
    if (filename.endsWith('.ts') || filename.endsWith('.tsx')) {
        src = tshot(src,filename);
    } 
    return transformer.transform(src, filename, options)
}





