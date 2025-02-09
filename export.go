package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"go/ast"
	"go/importer"
	"go/token"
	"go/types"

	//"go/types"
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"

	"golang.org/x/tools/go/packages"
)

type stdgoListType struct {
	Stdgo []string `json:"stdgo"`
}

type dataType struct {
	Args []string      `json:"args"`
	Pkgs []packageType `json:"pkgs"`
}
type packageType struct {
	Path  string     `json:"path"`
	Name  string     `json:"name"`
	Files []fileType `json:"files"`
}
type fileType struct {
	Path     string                   `json:"path"`
	Location string                   `json:"location"`
	Decls    []map[string]interface{} `json:"decls"`
	Doc      map[string]interface{}   `json:"doc"`
}
type excludesType struct {
	Excludes []string `json:"excludes"`
}

var fset *token.FileSet
var excludes map[string]bool
var stdgoList map[string]bool

func main() {
	//exclude types system
	excludesBytes, err := ioutil.ReadFile("excludes.json")
	if err != nil {
		fmt.Println(err)
		return
	}
	stdgoListBytes, err := ioutil.ReadFile("stdgo.json")
	var excludesData excludesType
	var stdgoDataList stdgoListType
	err = json.Unmarshal(excludesBytes, &excludesData)
	if err != nil {
		panic(err.Error())
	}
	excludes = make(map[string]bool, len(excludesData.Excludes))
	for _, exclude := range excludesData.Excludes {
		excludes[exclude] = true
	}

	err = json.Unmarshal(stdgoListBytes,&stdgoDataList)
	if err != nil {
		panic(err.Error())
	}
	stdgoList = make(map[string]bool,len(stdgoDataList.Stdgo))
	for _,stdgo := range stdgoDataList.Stdgo {
		stdgoList[stdgo] = true
	}
	//flags
	testBool := flag.Bool("test", false, "testing the go library in haxe")
	identBool := flag.Bool("ident", false, "ident json")
	flag.Parse()
	args := flag.Args()
	fmt.Println("ident:", *identBool, "test:", *testBool)
	localPath := args[len(args)-1]
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		return
	}
	err = os.Chdir(localPath)
	if err != nil {
		fmt.Println(err)
		return
	}
	args = args[0 : len(args)-1] //remove chdir

	//args = args[0:10]

	cfg := &packages.Config{Mode: packages.NeedName |
		packages.NeedSyntax | packages.NeedDeps |
		packages.NeedImports | packages.NeedTypes |
		packages.NeedFiles | packages.NeedTypes | packages.NeedTypesInfo}
	cfg.Tests = *testBool
	initial, err := packages.Load(cfg, args...)
	if err != nil {
		fmt.Println("load error:", err)
		return
	}

	data := parsePkgList(initial)

	data.Args = args
	var bytes []byte
	if *identBool {
		bytes, err = json.MarshalIndent(data, "", "    ")
	} else {
		bytes, err = json.Marshal(data)
	}
	if err != nil {
		fmt.Println("encoding err:", err)
		return
	}
	err = os.Chdir(cwd)
	if err != nil {
		fmt.Println(err)
		return
	}
	os.Remove("export.json")
	ioutil.WriteFile("export.json", bytes, 0644)
}

func parsePkgList(list []*packages.Package) dataType {
	data := dataType{}
	data.Pkgs = make([]packageType, len(list))
	for _, pkg := range list {
		syntax := parsePkg(pkg)
		if len(syntax.Files) > 1 {
			data.Pkgs = append(data.Pkgs, syntax)
		}
		for _, val := range pkg.Imports {
			if excludes[val.PkgPath] {
				continue
			}
			syntax := parsePkg(val)
			if stdgoList[val.PkgPath] {
				//stdgoVal := packages.Package{}
				//syntax2 := parsePkg(&stdgoVal)
				//_ = syntax2
				//merge the files together for the runner
			}
			if len(syntax.Files) > 1 {
				data.Pkgs = append(data.Pkgs, syntax)
			}
		}
	}
	return data
}

func parsePkg(pkg *packages.Package) packageType {
	fset = pkg.Fset
	data := packageType{}
	data.Name = pkg.Name
	data.Path = pkg.PkgPath
	data.Files = make([]fileType, len(pkg.Syntax))

	conf := types.Config{
		Importer: importer.Default(),
		//DisableUnusedImportCheck: true,
	}
	
	
	checker = types.NewChecker(&conf,pkg.Fset,pkg.Types,pkg.TypesInfo)

	for i, file := range pkg.Syntax {
		data.Files = append(data.Files, parseFile(file, pkg.GoFiles[i]))
	}
	return data
}

func parseFile(file *ast.File, path string) fileType {
	data := fileType{}
	data.Location = path
	data.Doc = parseData(file.Doc)
	path = filepath.Base(path)
	data.Path = path

	for _, decl := range file.Decls {
		obj := parseData(decl)
		data.Decls = append(data.Decls, obj)
	}
	return data
}
func parseBody(list []ast.Stmt) []map[string]interface{} {
	data := make([]map[string]interface{}, len(list))
	for i, obj := range list {
		data[i] = parseData(obj)
	}
	return data
}
func parseExprList(list []ast.Expr) []map[string]interface{} {
	data := make([]map[string]interface{}, len(list))
	//fmt.Println("list:",list)
	for i, obj := range list {
		data[i] = parseData(obj)
	}
	return data
}
func parseSpecList(list []ast.Spec) []map[string]interface{} {
	data := make([]map[string]interface{}, len(list))
	for i, obj := range list {
		switch obj := obj.(type) {
		case *ast.ValueSpec:
			constants := make([]bool, len(obj.Names))
			for i := range constants {
				constants[i] = obj.Names[i].Obj.Kind.String() == "const"
			}
			values := make([]map[string]interface{}, len(obj.Values))
			for i := range obj.Values {
				values[i] = parseData(obj.Values[i])
			}
			data[i] = map[string]interface{}{
				"id":        "ValueSpec",
				"names":     parseIdents(obj.Names),
				"type":      parseData(obj.Type),
				"values":    values,
				"constants": constants,
				"doc":       parseData(obj.Comment),
			}
		default:
			data[i] = parseData(obj)
		}
		data[i]["pos"] = fset.Position(obj.Pos()).Offset
		data[i]["end"] = fset.Position(obj.End()).Offset
	}
	return data
}

var marked map[string]bool
var checker *types.Checker

func parseType(node interface{}) map[string]interface{} {
	data := make(map[string]interface{})
	e := reflect.Indirect(reflect.ValueOf(node))
	if node == nil {
		return nil
	}
	if !e.IsValid() {
		return nil
	}
	data["id"] = getId(node)
	if data["id"] == "" {
		panic(data)
	}
	switch data["id"] {
	case "Named":
		named := node.(*types.Named)
		path := named.String()
		if !strings.Contains(path, "syscall/") && 
			!strings.Contains(path, "internal.") && 
			//!strings.Contains(path, "error") && 
			!strings.Contains(path,"reflect.") &&
			!strings.Contains(path,"runtime.") &&
			!strings.Contains(path,"sync.") &&
			!marked[path] {
			init := false
			if marked == nil {
				marked = make(map[string]bool)
				init = true
			}
			marked[path] = true
			data["underlying"] = parseType(named.Underlying())
			if init {
				marked = nil
			}
		}
		data["path"] = path
		return data
	case "Slice":
		s := node.(*types.Slice)
		data["elem"] = parseType(s.Elem())
		return data
	case "Struct":
		s := node.(*types.Struct)
		fields := make([]map[string]interface{}, s.NumFields())
		for i := 0; i < s.NumFields(); i++ {
			v := s.Field(i)
			fields[i] = map[string]interface{}{
				"name": v.Name(),
				"type": parseType(v.Type()),
			}
		}
		data["fields"] = fields
		return data
	case "Interface":
		s := node.(*types.Interface)
		data["numMethods"] = s.NumMethods()
		return data
	case "Pointer":
		s := node.(*types.Pointer)
		data["elem"] = parseType(s.Elem())
	case "Basic":
		s := node.(*types.Basic)
		data["kind"] = s.Kind() //is int
	case "Array":
		s := node.(*types.Array)
		data["elem"] = s.Elem()
		data["len"] = s.Len()
	case "Map":
		s := node.(*types.Map)
		data["elem"] = s.Elem()
		data["key"] = s.Key()
	case "Signature":
		s := node.(*types.Signature)
		data["variadic"] = s.Variadic()
		data["params"] = parseType(s.Params())
		data["results"] = parseType(s.Results())
		data["recv"] = parseType(s.Recv())
	case "Tuple":
		s := node.(*types.Tuple)
		data["len"] = s.Len()
		vars := make([]map[string]interface{},s.Len())
		for i := 0; i < s.Len(); i++ {
			a := s.At(i)
			vars[i] = parseType(a)
		}
		data["vars"] = vars
	case "Var":
		s := node.(*types.Var)
		data["name"] = s.Name()
		data["type"] = parseType(s.Type())
	case "Chan":
		s := node.(*types.Chan)
		data["type"] = parseType(s.Elem())
		data["dir"] = s.Dir()
	default:
		fmt.Println("unknown parse type id:", data["id"])
	}
	return data
}
func parseKind(val reflect.Value) interface{} {
	switch val.Kind() {
	case reflect.String:
		return val.String()
	case reflect.Ptr:
		return parseKind(reflect.New(val.Type().Elem()).Elem())
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return val.Int()
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return val.Uint()
	case reflect.Slice:
		return reflect.New(val.Type().Elem()).Elem().Interface()
	case reflect.Bool:
		return val.Bool()
	case reflect.Struct:
		i := val.Interface()
		return parseType(&i)
	case reflect.Interface:
		if val.CanSet() {
			i := val.Interface()
			return parseType(&i)
		}
		return nil
	default:
		fmt.Println("unknown type kind:", val.Kind())
		return nil
	}
}
func parseData(node interface{}) map[string]interface{} {
	data := make(map[string]interface{})
	switch node := node.(type) {
	case *ast.BasicLit:
		return parseBasicLit(node)
	case *ast.Ident:
		return parseIdent(node)
	default:
	}
	e := reflect.Indirect(reflect.ValueOf(node))
	if !e.IsValid() {
		return data
	}
	data["id"] = getId(node)
	et := e.Type()
	for i := 0; i < et.NumField(); i++ {
		field, val := et.Field(i), e.Field(i)
		if field.Name[:1] == strings.ToLower(field.Name[:1]) {
			continue
		}
		field.Name = strings.ToLower(field.Name[:1]) + field.Name[1:]
		_ = field
		value := val.Interface()

		switch value := value.(type) {
		case nil:
		case token.Pos:
			data[field.Name] = map[string]interface{}{
				"id":     "Pos",
				"string": "",
				"noPos":  value == token.NoPos,
			}
		case token.Token:
			data[field.Name] = value.String()
		case *ast.ArrayType, *ast.StructType, *ast.InterfaceType, *ast.MapType, *ast.ChanType:
			data[field.Name] = parseData(value)
		case *ast.BasicLit:
			data[field.Name] = parseBasicLit(value)
		case *ast.BadExpr, *ast.Ellipsis, *ast.FuncLit, *ast.CompositeLit, *ast.ParenExpr:
			data[field.Name] = parseData(value)
		case *ast.SelectorExpr, *ast.IndexExpr, *ast.SliceExpr, *ast.TypeAssertExpr, *ast.CallExpr, *ast.StarExpr, *ast.UnaryExpr, *ast.KeyValueExpr:
			data[field.Name] = parseData(value)
		case *ast.ExprStmt:
			data[field.Name] = map[string]interface{}{
				"id":  "ExprStmt",
				"x":   parseData(value.X),
				"pos": fset.PositionFor(value.X.Pos(), true).Offset,
				"end": fset.PositionFor(value.X.End(), true).Offset,
			}
		case *ast.BadStmt, *ast.DeclStmt, *ast.EmptyStmt, *ast.LabeledStmt, *ast.SendStmt, *ast.IncDecStmt, *ast.GoStmt, ast.DeferStmt:
			data[field.Name] = parseData(value)
		case *ast.ReturnStmt, *ast.BranchStmt, *ast.SelectStmt:
			data[field.Name] = parseData(value)
		case *ast.BinaryExpr:
			obj := parseData(value)
			data[field.Name] = obj
		case *ast.BlockStmt, *ast.IfStmt, *ast.CaseClause, *ast.SwitchStmt, *ast.ForStmt, *ast.RangeStmt, *ast.TypeSwitchStmt, *ast.CommClause, *ast.FuncType: //in scopes
			data[field.Name] = parseData(value)
		case *ast.AssignStmt:
			data[field.Name] = parseData(value)
		case *ast.GenDecl:
			file := ast.File{}
			file.Decls = append(file.Decls, value)
			data[field.Name] = parseFile(&file, "")
		case *ast.Ident:
			data[field.Name] = parseIdent(value)
		case ast.ChanDir, bool, string, int: //is an int
			data[field.Name] = value
		case ast.FieldList:
			data[field.Name] = parseFieldList(value.List)
		case *ast.FieldList:
			if value == nil {
				continue
			}
			data[field.Name] = parseFieldList(value.List)
		case []ast.Stmt:
			if value == nil {
				continue
			}
			data[field.Name] = parseBody(value)
		case []ast.Expr:
			data[field.Name] = parseExprList(value)
		case []ast.Spec:
			data[field.Name] = parseSpecList(value)
		case *ast.Object: //skip
		case []*ast.Ident:
			data[field.Name] = parseIdents(value)
		case []ast.Ident:
			list := make([]string, len(value))
			for i := range value {
				list[i] = value[i].Name
			}
			data[field.Name] = list
		case *ast.Scope:
		case []*ast.Comment:
			list := make([]string, len(value))
			for i := range value {
				list[i] = value[i].Text
			}
		case *ast.CommentGroup:
			var list []string
			if value == nil {
				list = []string{}
			} else {
				list = make([]string, len(value.List))
				for i := 0; i < len(list); i++ {
					list[i] = value.List[i].Text
				}
			}
			data[field.Name] = map[string]interface{}{
				"id":   "CommentGroup",
				"list": list,
			}
		default:
			fmt.Println("unknown parse data value:", reflect.TypeOf(value))
		}
	}
	switch node := node.(type) {
	case *ast.CompositeLit:
		data["typeLit"] = parseType(checker.TypeOf(node.Type))
	case *ast.SelectorExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.IndexExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.Ellipsis:
		data["type"] = parseType(checker.TypeOf(node.Elt))
	case *ast.ParenExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.SliceExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.TypeAssertExpr:
		data["typeX"] = parseType(checker.TypeOf(node.X))
		data["typeY"] = parseType(checker.TypeOf(node.Type))
	case *ast.StarExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.CallExpr:
		data["type"] = parseType(checker.TypeOf(node.Fun))
	case *ast.UnaryExpr:
		data["type"] = parseType(checker.TypeOf(node.X))
	case *ast.BinaryExpr:
		data["typeX"] = parseType(checker.TypeOf(node.X))
		data["typeY"] = parseType(checker.TypeOf(node.Y))
	case *ast.KeyValueExpr:
		data["typeKey"] = parseType(checker.TypeOf(node.Key))
		data["typeValue"] = parseType(checker.TypeOf(node.Value))
	case *ast.FuncDecl:
		data["pos"] = fset.Position(node.Pos()).Offset
		data["end"] = fset.Position(node.End()).Offset
	default:
	}
	return data
}
func parseIdents(value []*ast.Ident) []map[string]interface{} {
	list := make([]map[string]interface{}, len(value))
	for i := range value {
		list[i] = map[string]interface{}{
			"id":   "Ident",
			"type": parseType(checker.TypeOf(value[i])),
			"name": value[i].Name,
		}
	}
	return list
}
func parseIdent(value *ast.Ident) map[string]interface{} {
	if value == nil {
		return nil
	}
	data := map[string]interface{}{
		"id":   "Ident",
		"name": value.Name,
	}
	obj := checker.ObjectOf(value)
	if obj != nil {
		data["type"] = parseType(obj.Type())
	}
	return data
}
func parseBasicLit(value *ast.BasicLit) map[string]interface{} {
	output := ""
	switch value.Kind {
	case token.INT:
		i, err := strconv.ParseInt(value.Value, 0, 64)
		if err != nil {
			j, err2 := strconv.ParseUint(value.Value, 0, 64)
			if err2 != nil {
				fmt.Println("parse int 64 error:", err2)
				fmt.Println("parse uint 64 error:", err2)
			} else {
				output = fmt.Sprint(j)
			}
		} else {
			output = fmt.Sprint(i)
		}
	case token.FLOAT:
		i, err := strconv.ParseFloat(value.Value, 64)
		if err != nil {
			fmt.Println("parse float 64 error:", err)
		}
		output = fmt.Sprint(i)
	case token.CHAR:
		if len(value.Value) >= 2 && value.Value[0:1] == `'` {
			value.Value = value.Value[1 : len(value.Value)-1]
		}
		output = fmt.Sprint(value.Value)
	case token.STRING:
		if len(value.Value) >= 2 && value.Value[0:1] == `"` {
			value.Value = string(value.Value[1 : len(value.Value)-1])
		}
		output = fmt.Sprint(value.Value)
	case token.IMAG: //TODO: implement imaginary numbers (complex)
		output = value.Value[0 : len(value.Value)-1]
	}
	return map[string]interface{}{
		"id":    "BasicLit",
		"kind":  value.Kind.String(),
		"value": output,
	}
}
func getId(obj interface{}) string {
	if obj == nil {
		return ""
	}
	return reflect.TypeOf(obj).Elem().Name()
}
func parseFieldList(list []*ast.Field) map[string]interface{} {
	data := make([]map[string]interface{}, len(list))
	for i, field := range list {
		data[i] = parseField(field)
	}
	return map[string]interface{}{
		"id":   "FieldList",
		"list": data,
	}
}
func parseField(field *ast.Field) map[string]interface{} {
	names := make([]map[string]interface{}, len(field.Names))
	for i, name := range field.Names {
		names[i] = map[string]interface{}{
			"id":   "Ident",

			"name": name.Name,
		}
	}
	var tag map[string]interface{} = nil
	if field.Tag != nil {
		tag = parseBasicLit(field.Tag)
	}
	return map[string]interface{}{
		//"doc": parseData(field.Doc)
		"names": names,
		"type":  parseData(field.Type),
		"tag":   tag,
		//"comment": parseData(field.Comment)
	}
}
