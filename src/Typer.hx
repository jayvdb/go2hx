import haxe.io.Path;
import haxe.ds.StringMap;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassKind;
import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ModuleType;
import haxe.macro.Expr;
import haxe.DynamicAccess;
import sys.FileSystem;

final gostdList = [for (name in FileSystem.readDirectory("stdgo")) Path.withoutExtension(name).toLowerCase()];
function main(data:DataType){
    var list:Array<Module> = [];
    for (pkg in data.pkgs) {
        if (pkg.files == null)
            continue;
        var module:Module = {path: pkg.path,files: []};
        var main:FileType = null;
        for (file in pkg.files) {
            if (file.decls == null)
                continue;
            file.path = Path.normalize(file.path);
            var index = file.path.lastIndexOf("/");
            if (index != -1)
                file.path = file.path.substr(index + 1);
            file.path = Path.withoutExtension(file.path);
            var data:FileType = {name: file.path,imports: [],defs: []};
            data.name = normalizePath(data.name);
            var info:Info = {types: []};
            var declFuncs:Array<Ast.FuncDecl> = [];
            for (decl in file.decls) {
                switch decl.id {
                    case "GenDecl":
                        for (spec in cast(decl.specs,Array<Dynamic>)) {
                            switch spec.id {
                                case "ImportSpec":
                                    data.imports.push(typeImport(spec,info));
                                case "ValueSpec":
                                    data.defs = data.defs.concat(typeValue(spec,info));
                                case "TypeSpec":
                                    data.defs.push(typeType(spec,info));
                                default:
                                    error("unknown spec: " + spec.id);
                            }
                        }
                    case "FuncDecl":
                        declFuncs.push(decl);
                    default:

                }
            }
            for (decl in declFuncs) { //parse function bodies last
                data.defs.push(typeFunc(decl,info));
            }
            module.files.push(data);
        }
        list.push(module);
    }
    return list;
}
function typeStmt(stmt:Dynamic,info:Info):Expr {
    if (stmt == null)
        return null;
    var def = switch stmt.id {
        case "ReturnStmt": typeReturnStmt(stmt,info);
        case "IfStmt": typeIfStmt(stmt,info);
        case "ExprStmt": typeExprStmt(stmt,info);
        case "AssignStmt": typeAssignStmt(stmt,info);
        case "ForStmt": typeForStmt(stmt,info);
        case "SwitchStmt": typeSwitchStmt(stmt,info);
        case "TypeSwitchStmt": typeTypeSwitchStmt(stmt,info);
        case "DeclStmt": typeDeclStmt(stmt,info);
        case "RangeStmt": typeRangeStmt(stmt,info);
        case "DeferStmt": typeDeferStmt(stmt,info);
        case "IncDecStmt": typeIncDecStmt(stmt,info);
        case "LabeledStmt": typeLabeledStmt(stmt,info);
        case "BlockStmt": typeBlockStmt(stmt,info);
        case "BadStmt": error("BAD STATEMENT TYPED"); null;
        case "GoStmt": typeGoStmt(stmt,info);
        default:
            error("unknown stmt id: " + stmt.id);
            null;
    }
    return def == null ? {error("stmt null: " + stmt.id); null;} : {
        expr: def,
        pos: null,
    };
}
var errorCache = new StringMap<Bool>();
function error(message:String) {
    if (!errorCache.exists(message))
        trace(message);
    errorCache.set(message,true);
}
//STMT
function typeGoStmt(stmt:Ast.GoStmt,info:Info):ExprDef {
    return null;
}
function typeBlockStmt(stmt:Ast.BlockStmt,info:Info):ExprDef {
    return EBlock([
        for (stmt in stmt.list) typeStmt(stmt,info)
    ]);
}
function typeLabeledStmt(stmt:Ast.LabeledStmt,info:Info):ExprDef {
    return null;
}
function typeIncDecStmt(stmt:Ast.IncDecStmt,info:Info):ExprDef {
    return null;
}
function typeDeferStmt(stmt:Ast.DeferStmt,info:Info):ExprDef {
    return null;
}
function typeRangeStmt(stmt:Ast.RangeStmt,info:Info):ExprDef {
    return null;
}
function typeDeclStmt(stmt:Ast.DeclStmt,info:Info):ExprDef {
    return null;
}
function typeTypeSwitchStmt(stmt:Ast.TypeSwitchStmt,info:Info):ExprDef {
    return null;
}
function typeSwitchStmt(stmt:Ast.SwitchStmt,info:Info):ExprDef {
    return null;
}
function typeForStmt(stmt:Ast.ForStmt,info:Info):ExprDef {
    return null;
}
function typeAssignStmt(stmt:Ast.AssignStmt,info:Info):ExprDef {
    return null;
}
function typeExprStmt(stmt:Ast.ExprStmt,info:Info):ExprDef {
    return typeExpr(stmt.x,info).expr;
}
function typeIfStmt(stmt:Ast.IfStmt,info:Info):ExprDef {
    return EBlock([
        typeStmt(stmt.init,info),
        {pos: null, expr: EIf(typeExpr(stmt.cond,info),typeStmt(stmt.body,info),typeStmt(stmt.elseStmt,info))},
    ]);
}
function typeReturnStmt(stmt:Ast.ReturnStmt,info:Info):ExprDef {
    if (stmt.results.length == 0)
        return EReturn();
    if (stmt.results.length == 1)
        return EReturn(typeExpr(stmt.results[0],info));
    //multireturn
    return EReturn();
}
function typeExprType(expr:Dynamic,info:Info):ComplexType { //get the type of an expr
    if (expr == null)
        return null;
    return switch expr.id {
        case "MapType": mapType(expr,info);
        case "ChanType": chanType(expr,info);
        case "InterfaceType": interfaceType(expr,info);
        case "StructType": structType(expr,info);
        case "FuncType": funcType(expr,info);
        case "ArrayType": arrayType(expr,info);
        case "StarExpr": starType(expr,info); //pointer
        case "Ident": identType(expr,info); //identifier type
        case "SelectorExpr": selectorType(expr,info);//path
        case "Ellipsis": ellipsisType(expr,info); //Rest arg
        default: error("Type expr unknown: " + expr); null;
    }
}
//TYPE EXPR
function mapType(expr:Ast.MapType,info:Info):ComplexType {
    return null;
}
function chanType(expr:Ast.ChanType,info:Info):ComplexType {
    return null;
}
function interfaceType(expr:Ast.InterfaceType,info:Info):ComplexType {
    return null;
}
function structType(expr:Ast.StructType,info:Info):ComplexType {
    return null;
}
function funcType(expr:Ast.FuncType,info:Info):ComplexType {
    return null;
}
function arrayType(expr:Ast.ArrayType,info:Info):ComplexType {
    return null;
}
function starType(expr:Ast.StarExpr,info:Info):ComplexType {
    return null;
}
function identType(expr:Ast.Ident,info:Info):ComplexType {
    return null;
}
function selectorType(expr:Ast.SelectorExpr,info:Info):ComplexType {
    return null;
}
function ellipsisType(expr:Ast.Ellipsis,info:Info):ComplexType {
    return null;
}
function typeExpr(expr:Dynamic,info:Info):Expr {
    if (expr == null)
        return null;
    var def = switch expr.id {
        case "Ident": typeIdent(expr,info);
        case "CallExpr": typeCallExpr(expr,info);
        case "BasicLit": typeBasicLit(expr,info);
        case "UnaryExpr": typeUnaryExpr(expr,info);
        case "SelectorExpr": typeSelectorExpr(expr,info);
        case "BinaryExpr": typeBinaryExpr(expr,info);
        case "FuncLit": typeFuncLit(expr,info);
        case "CompositeLit": typeCompositeLit(expr,info);
        case "SliceExpr": typeSliceExpr(expr,info);
        case "TypeAssertExpr": typeAssertExpr(expr,info);
        case "IndexExpr": typeIndexExpr(expr,info);
        case "StarExpr": typeStarExpr(expr,info);
        case "ParenExpr": typeParenExpr(expr,info);
        case "Ellipsis": typeEllipsis(expr,info);
        case "KeyValueExpr": typeKeyValueExpr(expr,info);
        case "BadExpr": error("BAD EXPRESSION TYPED"); null;
        default:
            trace("unknown expr id: " + expr.id);
            null;
    };
    return def == null ? {error("expr null: " + expr.id); null;} : {
        expr: def,
        pos: null,
    };
}
//EXPR
function typeKeyValueExpr(expr:Ast.KeyValueExpr,info:Info):ExprDef {
    return null;
}
function typeEllipsis(expr:Ast.Ellipsis,info:Info):ExprDef {
    return null;
}
function typeIdent(expr:Ast.Ident,info:Info):ExprDef {
    return EConst(CIdent(ident(expr.name)));
}
function typeCallExpr(expr:Ast.CallExpr,info:Info):ExprDef {
    switch expr.fun.id {
        case "SelectorExpr":
            expr.fun.sel.name = untitle(expr.fun.sel.name); //all functions lowercase
    }
    return ECall(typeExpr(expr.fun,info),[for (arg in expr.args) typeExpr(arg,info)]);
}
function typeBasicLit(expr:Ast.BasicLit,info:Info):ExprDef {
    return switch expr.kind {
        case STRING: EConst(CString(expr.value));
        case INT: EConst(CInt(expr.value));
        case FLOAT: EConst(CFloat(expr.value));
        case CHAR: EConst(CString(expr.value));
        case IDENT: EConst(CIdent(ident(expr.value)));
        default:
            error("basic lit kind unknown: " + expr.kind);
            null;
    }
}
function typeUnaryExpr(expr:Ast.UnaryExpr,info:Info):ExprDef {
    return null;
}
function typeCompositeLit(expr:Ast.FuncLit,info:Info):ExprDef {
    return null;
}
function typeFuncLit(expr:Ast.FuncLit,info:Info):ExprDef {
    return null;
}
function typeBinaryExpr(expr:Ast.BinaryExpr,info:Info):ExprDef {
    return null;
}
function typeSelectorExpr(expr:Ast.SelectorExpr,info:Info):ExprDef {
    var count = 0;
    function firstSelector(selector:Ast.Expr) {
        count++;
        return switch selector.x.id {
            case "SelectorExpr": return selector.x;
            case "Ident": return selector;
            default: null;
        }
    }
    var first = firstSelector(expr);
    if (gostdList.indexOf(first.x.name) != -1) {
        first.x.name = title(first.x.name);
        if (count > 1) {
            first.x = {
                id: "SelectorExpr",
                x: {id: "Ident",name: "gostd"},
                sel: first.x,
            };
        }
    }
    return EField(typeExpr(expr.x,info),expr.sel.name);
}
function typeSliceExpr(expr:Ast.SliceExpr,info:Info):ExprDef {
    var x = typeExpr(expr.x,info);

    return null;
}
function typeAssertExpr(expr:Ast.TypeAssertExpr,info:Info):ExprDef {
    return ECast(expr.x,typeExprType(expr.type,info));
}
function typeIndexExpr(expr:Ast.IndexExpr,info:Info):ExprDef {
    return EArray(typeExpr(expr.x,info),typeExpr(expr.index,info));
}
function typeStarExpr(expr:Ast.StarExpr,info:Info):ExprDef {
    return null;
}
function typeParenExpr(expr:Ast.ParenExpr,info:Info):ExprDef {
    return EParenthesis(typeExpr(expr.x,info));
}
//SPECS
function typeFunc(decl:Ast.FuncDecl,info:Info):TypeDefinition {
    var exprs:Array<Expr> = [];
    if (decl.body.list != null) 
        exprs = [for (stmt in decl.body.list) typeStmt(stmt,info)];
    var block:Expr = {
        expr: EBlock(exprs),
        pos: null
    };
    var def:TypeDefinition = {
        name: decl.name.name,
        pos: null,
        pack: [],
        fields: [],
        kind: TDField(FFun({ret: typeFieldListRes(decl.type.results),params: null,expr: block, args: typeFieldListArgs(decl.type.params)})), //args = Array<FunctionArg>, ret = ComplexType
    };
    if (decl.recv != null) { //now is a static extension function
           def.meta = [{pos: null,name: ":using"}];
    }
    return def;
}
function typeFieldListRes(field:Ast.FieldList) { //A single type or Anonymous struct type
    return null;
}
function typeFieldListArgs(field:Ast.FieldList):Array<FunctionArg> { //Array of FunctionArgs
    return [];
}
function typeType(spec:Ast.TypeSpec,info:Info):TypeDefinition {
    return {
        name: spec.name.name,
        pos: null,
        params: [], //<---- fill this for typedefs
        fields: [], //<--- this for interfaces
        pack: [],
        kind: TypeDefKind.TDStructure,
    };
}
function typeImport(imp:Ast.ImportSpec,info:Info):ImportType {
    var path = (imp.path.value : String).split("/");
    if (gostdList.indexOf(path[0]) != -1)
        path.unshift("stdgo");
    path[path.length - 1] = title(path[path.length - 1]);
    info.types[untitle(path[path.length - 1])] = path.join(".");
    return {
        path: path,
        alias: imp.name,
    }
}
function typeValue(value:Ast.ValueSpec,info:Info):Array<TypeDefinition> {
    var defs:Array<TypeDefinition> = [];
    for (name in value.names) {
        var ty = ComplexType.TPath({pack: ["TYPE"],name: "TYPE"});
        defs.push({
            name: name.name,
            pos: null,
            pack: [],
            fields: [],
            kind: TDField(FVar(ty,null),null)
        });
    }
    return defs;
}
function ident(name:String):String {
    if (name == "nil")
        name = "null";
    return name;
}
private function normalizePath(path:String):String {
    path = StringTools.replace(path,".","_");
    path = StringTools.replace(path,":","_");
    path = StringTools.replace(path,"-","_");
    return path;
}
private function title(string:String):String {
    return string.charAt(0).toUpperCase() + string.substr(1);
}
private function untitle(string:String):String {
    return string.charAt(0).toLowerCase() + string.substr(1);
}
typedef Info = {types:Map<String,String>}

typedef DataType = {args:Array<String>,pkgs:Array<PackageType>};
typedef PackageType = {path:String,name:String,files:Array<{path:String,decls:Array<Dynamic>}>};
typedef Module = {path:String,files:Array<FileType>}
typedef ImportType = {path:Array<String>,alias:String}
typedef FileType = {name:String,imports:Array<ImportType>,defs:Array<TypeDefinition>};
