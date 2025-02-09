package stdgo;

import haxe.macro.PositionTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
import haxe.io.Bytes;
import haxe.Exception;
import haxe.macro.ExprTools;
import haxe.macro.Context;

class Go {
	public static var addressIndex:Int = 1;

	public static function defaultValue(t:ComplexType, pos:Position, strict:Bool = true):Expr {
		switch t {
			case TFunction(args, ret):
				return macro null;
			case TPath(p):
				var name = p.name;
				if (p.name == "StdGoTypes" || p.name == "StdTypes")
					name = p.sub;
				switch name {
					case "Void":
						return null;
					case "GoArray":
						return macro new $p();
					case "GoByte", "GoRune", "GoInt", "GoUInt", "GoUInt8", "GoUInt16", "GoUInt32", "GoUInt64", "GoInt8",
						"GoInt16", "GoInt32", "GoInt64", "GoFloat32", "GoFloat64", "GoComplex64", "GoComplex128":
						if (strict)
							return macro(0 : $t);
						return macro 0;
					case "AnyInterface":
						return macro null;
					case "GoDynamic", "Any", "Dynamic":
						return macro {};
					case "Bool":
						return macro false;
					case "Pointer", "PointerWrapper", "GoArrayPointer":
						return macro null;
					case "GoString", "String":
						if (strict)
							return macro("" : GoString);
						return macro "";
					case "Chan":
						return macro null;
					case "GoMap":
						switch p.params[1] { // value default value add
							case TPType(t):
								return macro new $p(${defaultValue(t, null, false)}).setNull();
							default:
						}
					default:
						return macro new $p();
				}
			case TAnonymous(fields):
				return {
					pos: pos,
					expr: EObjectDecl([
						for (field in fields) {
							var type:ComplexType = null;
							switch field.kind {
								case FVar(t, e):
									type = t;
								default:
							}
							{
								field: field.name,
								expr: defaultValue(type, pos),
							};
						}
					])
				};
			default:
				trace("unknown type for default value: " + t);
		}
		return macro null;
	}

	static function getMetaLength(meta:Metadata):ExprDef {
		for (m in meta) {
			if (m.name != ":length")
				continue;
			return m.params[0].expr;
		}
		return EConst(CIdent("0"));
	}

	static private function getData(expr:Expr):Expr {
		return switch expr.expr {
			case ECheckType(e, t): return e;
			case EParenthesis(e): return getData(e);
			default: expr;
		}
	}

	static private function getType(expr:Expr):ComplexType {
		var type:ComplexType = null;
		if (expr == null)
			return type;
		switch expr.expr {
			case ECheckType(e, t):
				type = t;
			case EParenthesis(e):
				type = getType(e);
			default:
		}
		return type;
	}

	public static macro function make(t:Expr, ?size:Expr, ?cap:Expr) { // for slice/array and map
		// convert from int64 to int
		if (size == null || size.expr.match(EConst(CIdent("null"))))
			size = macro 0;
		if (cap == null || cap.expr.match(EConst(CIdent("null"))))
			cap = macro 0;
		var type = Context.followWithAbstracts(ComplexTypeTools.toType(getType(t)));
		var ct = Context.toComplexType(type);
		if (ct == null)
			throw ct;
		var func = null;
		func = function():Expr {
			switch ct {
				case TPath(p):
					var name = p.name;
					switch name {
						case "SliceData":
							p = {name: "Slice",pack: [], params: p.params};
							if (size == null)
								return macro new $p();
							var value:Expr = null;
							switch p.params[0] {
								case TPType(t):
									t = Context.toComplexType(Context.follow(ComplexTypeTools.toType(t)));
									value = defaultValue(t, Context.currentPos());
								default:
							}
							return macro {
								var slice = new $p();
								var size = ($size : GoInt32).toBasic();
								var value = $value;
								slice.grow(size);
								var i = 0;
								while (i < size) {
									slice[i] = value;
									i++;
								}
								slice;
							};
						case "Vector":
							throw("cannot make GoArray must be type generated");
						case "MapData":
							p = {name: "GoMap",pack: [], params: p.params};
							switch p.params[1] {
								case TPType(t):
									t = Context.toComplexType(Context.follow(ComplexTypeTools.toType(t)));
									return macro new $p(${defaultValue(t, Context.currentPos(), false)});
								default:
							}
							return null;
						case "Chan":
							switch p.params[0] {
								case TPType(t):
									t = Context.toComplexType(Context.follow(ComplexTypeTools.toType(t)));
									return macro new $p($size, ${defaultValue(t, Context.currentPos(), false)});
								default:
							}
							return null;
						default:
							trace("make unknown tpath: " + p);
							return null;
					}
				default:
					trace("make unknown type: " + t);
					return null;
			}
		}
		return func();
	}

	public static macro function copy<T>(dst:Expr, src:ExprOf<Slice<T>>) {
		var type = Context.toComplexType(Context.follow(Context.typeof(dst)));
		switch type {
			case TPath(p):
				switch p.name {
					case "Slice":
						return macro {
							var src = $src;
							var dst = $dst;
							var length = dst.length >= src.length ? src.length : dst.length; // min length
							for (i in 0...length.toBasic()) {
								dst[i] = src[i];
							}
							length;
						}
					default:
						trace("unknown copy type path: " + p.name);
				}
			default:
				trace("unknown copy type: " + type);
		}
		return src;
	}

	public static macro function passCopy(expr) { // slices and maps are ref types
		var type = Context.follow(Context.typeof(expr));
		var exception = false;
		switch expr.expr {
			case ENew(t, params):
				exception = true;
			case EArrayDecl(values):
				exception = true;
			case EObjectDecl(fields):
				exception = true;
			case EIs(e, t):
				exception = true;
			case EConst(c):
				switch c {
					case CIdent(s):
						if (s == "null") exception = true;
					default:
				}
			case EBinop(op, e1, e2):
				exception = true;
			case ECall(e, params):
				switch e.expr {
					case EField(f, field):
						switch f.expr {
							case EConst(c):
								switch c {
									case CIdent(s):
										trace("s: " + s);
										if (s == "Go" || s == "Map" || s == "Array" || s == "Slice") // map and array is by ref
											exception = true;
									default:
								}
							default:
						}
					default:
				}
			case EField(e, field):
				exception = true;
			case EArray(e1, e2): // expr[i] : passthrough
			default:
				trace("expr: " + expr.expr);
		}
		if (isBasic(type) || exception) {
			return expr;
		} else {
			switch type {
				case TAbstract(t, params):
					var t = t.get();
					if (t.pack.length == 1 && t.pack[0] == "stdgo" && (t.name == "GoUInt64" || t.name == "GoInt64"))
						return macro $expr.copy();
				case TInst(t, params):
					var t = t.get();
					switch t.pack.join(".") + t.name {
						case "Errors":
							return macro $expr.copy();
					}
					var fields = t.fields.get();
					fields.sort(function(a, b) {
						return Context.getPosInfos(a.pos).min - Context.getPosInfos(b.pos).min;
					});
					var values = [];
					var main = ExprTools.toString(expr);
					for (field in fields) {
						switch field.kind {
							case FVar(read, write):
								values.push('$main.' + field.name);
							case FMethod(k):
						}
					}
					values.sort(function(a, b) {
						return 0;
					});
					var str = "new " + t.pack.join(".") + t.name + '(${values.join(",")})';
					var init = Context.parse(str, Context.currentPos());
					return macro $init;
				case TMono(t):
					var t = t.get();
					switch t {
						case null:
						default:
							trace("unknown tmono type: " + t);
					}
				case TDynamic(t):
					trace("t " + t.getName());
				default:
					trace("copy type unknown: " + type);
			}
			return expr;
		}
	}

	public static macro function isNull(expr:Expr) {
		var type = Context.follow(Context.typeof(expr));
		switch type {
			case TMono(t):
				type = t.get();
				if (type == null)
					return macro true;
			default:
		}
		switch type {
			case TAbstract(t, params):
				var t = t.get();
				switch t.name {
					case "Slice":
						return macro $expr.length == 0;
					case "PointerWrapper":
						return macro Go.isNull($expr._value_);
					case "Pointer":
						return macro Go.isNull($expr._value_);
					case "AnyInterface":
						return macro Go.isNull($expr.value);
					case "GoArray":
						return macro false;
					case "Any", "GoMap":
						return macro $expr.isNull();
					default:
						trace("unknown abstract: " + t.name);
				}
			case TDynamic(t):
				if (t == null)
					return macro true;
			case TFun(args, ret):
				return macro false;
			case TInst(t, params):

			default:
				trace("unknown type: " + type);
		}
		return macro $expr == null;
	}

	public static macro function equals(a:Expr, b:Expr) {
		var type = Context.follow(Context.typeof(a));
		var exprs:Array<Expr> = [];
		switch a.expr {
			case ENew(t, params):
				exprs.push(macro var a = $a);
				exprs.push(macro var b = $b);
				a = macro $i{"a"};
				b = macro $i{"b"};
			default:
		}
		switch type {
			case TAbstract(t, params):
				var t = t.get();
				switch t.name {
					case "GoArray", "Slice":
						exprs.push(macro if ($a.length != $b.length)
							return false);
						exprs.push(macro for (i in 0...$a.length.toBasic()) {
							if (!Go.equals($a[i], $b[i]))
								return false;
						});
					default:
				}
			case TInst(t, params):
				var t = t.get();
				var fields = t.fields.get();
				for (field in fields) {
					if (field.name == "_address_" || field.name == "_" || field.name == "__")
						continue;
					switch field.type {
						case TFun(args, ret):

						default:
							var fieldName = field.name;
							exprs.push(macro if ($a.$fieldName != $b.$fieldName)
								return false);
					}
				}
			default:
		}
		if (exprs.length == 0)
			return macro $a == $b;
		exprs.push(macro return true);
		return macro {
			function a()
				$b{exprs};
			a();
		};
	}
	public static macro function fromInterface(expr) {
		function parens(expr) {
			return switch expr.expr {
				case EParenthesis(e): parens(e);
				default: expr;
			}
		}
		expr = parens(expr);
		switch expr.expr {
			case ECheckType(e, ct):
				var t = Context.follow(ComplexTypeTools.toType(ct));
				var isInterface = false;
				switch t {
					case TInst(t, params):
						isInterface = t.get().isInterface;
					default:
				}
				if (isInterface) {
					return macro $e.valueInterface != null ? ($e.valueInterface : $ct) : ($e.value : $ct);
				}
				return macro ($e.value : $ct);
			default:
				throw "not a checkType";
		}
	}
	// GOROUTINE
	public static macro function routine(expr) {
		return expr;
	}
	public static macro function toInterface(expr) {
		var t = Context.follow(Context.typeof(expr));
		switch t {
			case TAbstract(t, params):
				var t = t.get();
				if (t.name == "AnyInterface" && t.pack.length == 1 && t.pack[0] == "stdgo") {
					return expr; //prevent interface{} inside interface{}
				}
			default:
		}
		var ty = gtDecode(t);
		var exprInterface = macro null;
		switch t {
			case TAbstract(t, params):
				var t = t.get();
				if (t.impl != null) {
					var fields = t.impl.get().statics.get();
					for (field in fields) {
						if (field.name == "toInterface") {
							exprInterface = macro $expr.toInterface();
						}
					}
				}
			default:
		}
		return macro new AnyInterface($expr,$exprInterface,new stdgo.reflect.Reflect.Type($ty));
	}

	public static macro function assignable(expr:Expr) {
		function parens(expr) {
			return switch expr.expr {
				case EParenthesis(e): parens(e);
				default: expr;
			}
		}
		expr = parens(expr);
		switch expr.expr {
			case ECheckType(e, t):
				var t = Context.follow(ComplexTypeTools.toType(t));
				if (t == null)
					throw "complexType converted to type is null";
				var value = gtDecode(t);
				return macro $e.type.assignableTo(new stdgo.reflect.Reflect.Type($value));
			default:
				throw "unknown assignable expr: " + expr.expr;
		}
	}

	public static function createAnonType(pos:Position, fields:Array<Field>, params:Array<Expr>):Expr {
		return {
			pos: pos,
			expr: EObjectDecl([
				for (i in 0...fields.length) {
					var expr:Expr = macro null;
					if (params[i] == null) {
						switch fields[i].kind {
							case FVar(t, e):
								expr = defaultValue(t, pos);
							default: // FFunc is nil by default
						}
					} else {
						expr = params[i];
					}
					{
						field: fields[i].name,
						expr: expr,
					};
				}
			])
		};
	}

	static function escapeParens(expr:Expr):Expr {
		while (true) {
			switch expr.expr {
				case EParenthesis(e):
					expr = e;
				default:
					break;
			}
		}
		return expr;
	}

	public static macro function pointer(expr:Expr) {
		expr = escapeParens(expr);
		var isRealPointer = false;
		var type = Context.follow(Context.typeof(expr));
		switch type {
			case TMono(t):
				type = t.get();
			default:
		}
		if (type == null)
			return macro null;
		switch type {
			case TAbstract(t, params):
				var t = t.get();
				switch t.name {
					case "GoArray", "Slice", "Map":
						return macro new stdgo.Pointer.PointerWrapper($expr);
					case "GoString", "String", "Bool", "GoInt", "GoFloat", "GoUInt", "GoRune", "GoByte", "GoInt8", "GoInt16", "GoInt32", "GoInt64", "GoUInt8",
						"GoUInt16", "GoUInt32", "GoUInt64", "GoComplex", "GoComplex64", "GoComplex128":
						isRealPointer = true;
					case "Pointer", "PointerWrapper": // double or even triple pointer
						isRealPointer = true;
				}
			case TAnonymous(a):
			case TInst(t, params):
				var t = t.get();
				if (t.name == "String")
					isRealPointer = true;
			case TDynamic(t):
				return macro null;
			default:
				trace("unknown make pointer type: " + type);
		}
		var declare:Bool = false;
		switch expr.expr {
			case EArray(e1, e2):
				var t = Context.follow(Context.typeof(e1));
				switch t {
					case TAbstract(t, params):
						var t = t.get();
						if (t.name == "Slice") {
							if (isRealPointer)
								return macro {
									var _offset_ = ${e1}.getOffset();
									var _address_ = ${e1}._address_ + _offset_ + ${e2};
									new stdgo.Pointer(new stdgo.Pointer.PointerData(() -> ${e1}.getUnderlying()[${e2} + _offset_],
										(v) -> ${e1}.getUnderlying()[${e2} + _offset_] = v, _address_));
								};
							return macro {
								var _offset_ = ${e1}.getOffset();
								new stdgo.PointerWrapper(${e1}.getUnderlying()[${e2} + _offset_]);
							};
						}
					default:
				}
			case ENew(t, params):
				declare = true;
			case ECheckType(e, t):
				switch e.expr {
					case EConst(c):
						declare = true;
					default:
				}
			case EConst(c):
				
			default:
		}
		if (isRealPointer) {
			if (declare)
				return macro {
					var e = $expr;
					new stdgo.Pointer(new stdgo.Pointer.PointerData(() -> e, (v) -> e = v, ++Go.addressIndex));
				};
			return macro new stdgo.Pointer(new stdgo.Pointer.PointerData(() -> $expr, (v) -> $expr = v, ++Go.addressIndex));
		}
		if (declare)
			return macro {
				var e = $expr;
				new stdgo.PointerWrapper(e);
			};
		return macro new stdgo.PointerWrapper($expr);
	}

	public static macro function recover() {
		return untyped macro {
			var r = stdgo.runtime.Runtime.newRuntime(recover_exception.toString());
			recover_exception = null;
			r;
		}
	}

	public static macro function range(expr) {
		var type = Context.follow(Context.typeof(expr));
		switch type {
			case TMono(t):
				type = t.get();
			default:
		}
		switch type {
			case TAbstract(t, params):
				var t = t.get();
				switch t.name {
					case "GoString", "Slice", "GoArray", "Array", "GoMap":
						return macro $expr.keyValueIterator();
					default:
						throw "unknown type abstract range: " + t.name;
				}
			case TAnonymous(a):
				throw "unknown anon range type: " + [for (field in a.get().fields) field.name];
			case TInst(t, params):
				var t = t.get();
				if (t.name == "Chan" && t.params.length == 1 && t.pack.length == 1) {
					return macro $expr.keyValueIterator();
				}
				throw "unknown TInst range type: " + t;
			default:
				throw "unknown range type: " + type;
		}
	}

	public static macro function cfor(cond, post, expr) {
		#if !display
		var func = null;
		func = function(expr:haxe.macro.Expr) {
			return switch (expr.expr) {
				case EContinue: macro {$post; $expr;}
				case EWhile(_, _, _): expr;
				case ECall(macro cfor, _): expr;
				case EFor(_): expr;
				// case EIn(_): expr;
				default: haxe.macro.ExprTools.map(expr, func);
			}
		}
		expr = func(expr);
		#end
		var exprMacro = macro {
			while ($cond) {
				$expr;
				$post;
			}
		};
		return exprMacro;
	}

	static function isBasic(type:haxe.macro.Type):Bool {
		return switch type {
			case TAbstract(t, params):
				switch (t.get().name) {
					case "Bool":
					case "Float":
					case "Int":
					case "String", "GoString":
					default:
						false;
				}
				true;
			default:
				false;
		}
	}
	#if macro
	//reflect decode
	private static function gtParams(params:Array<haxe.macro.Type>):Array<Expr> {
		var pTypes = [];
		for (i in 0...params.length)
			pTypes.push(gtDecode(params[i]));
		return pTypes;
	}
	
	public static function gtDecode(t:haxe.macro.Type):Expr {
		var ret = macro stdgo.reflect.Reflect.GT_enum.GT_invalid;
		switch (t) {
			case TMono(ref):
				return macro stdgo.reflect.Reflect.GT_enum.GT_unsafePointer;
			case TType(ref, params):
				var ref = ref.get();
				var t = gtDecode(ref.type);
				var methods = macro [];
				var interfaces = macro [];
				ret = macro stdgo.reflect.Reflect.GT_enum.GT_namedType($v{ref.pack.join(".")},$v{parseModule(ref.module)},$v{ref.name},$methods,$interfaces,$t);
			case TAbstract(ref, params):
				var sref:String = ref.toString();
				switch (sref) {
					case "haxe.Rest":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_variadic($a{gtParams(params)});
					case "stdgo.Slice":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_slice($a{gtParams(params)});
					case "stdgo.GoArray":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_array(${gtParams(params)[0]}, -1); // TODO go2hx does not store the length in the type
					case "stdgo.Pointer", "stdgo.PointerWrapper", "stdgo.GoArrayPointer":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_ptr($a{gtParams(params)});
					case "stdgo.GoMap":
						var ps = gtParams(params);
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_map($a{ps});
					case "stdgo.GoInt8":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_int8;
					case "stdgo.GoInt16":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_int16;
					case "stdgo.GoInt32":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_int32;
					case "stdgo.GoInt", "Int":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_int;
					case "stdgo.GoInt64":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_int64;
					case "stdgo.GoUInt8":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_uint8;
					case "stdgo.GoUInt16":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_uint16;
					case "stdgo.GoUInt":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_uint;
					case "stdgo.GoUInt32":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_uint32;
					case "stdgo.GoUInt64":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_uint64;
					case "stdgo.GoString", "String":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_string;
					case "stdgo.GoComplex64":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_complex64;
					case "stdgo.GoComplex128":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_complex128;
					case "stdgo.ComplexType":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_complex128;
					case "stdgo.GoFloat32":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_float32;
					case "stdgo.GoFloat64":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_float64;
					case "stdgo.FloatType":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_float64;
					case "Bool":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_bool;
					case "stdgo.AnyInterface":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_interface("","","interface{}",[]);
					case "Void":
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_invalid; // Currently no value is supported for Void however in the future, there will be a runtime value to match to it. HaxeFoundation/haxe-evolution#76
					default:
						var ref = ref.get();
						var interfaces:Array<Expr> = [];
						for (t in ref.to) {
							switch t.t {
								case TInst(tt, params):
									if (tt.get().isInterface)
										interfaces.push(gtDecode(t.t));
								default:
							}
						}
						ret = macro stdgo.reflect.Reflect.GT_enum.GT_namedType(
							$v{ref.pack.join(".")},
							$v{ref.module},$v{ref.name},
							[],
							$a{interfaces},
							${gtDecode(ref.type)}
						);
				}
			case TInst(ref, params):
				var ref = ref.get();
				if (params.length == 1 && ref.pack.length == 1 && ref.pack[0] == "stdgo" && ref.name == "Chan") {
					ret = macro stdgo.reflect.Reflect.GT_enum.GT_chan($a{gtParams(params)});
				}else{
					if (ref.isInterface) {
						ret = gtDecodeInterfaceType(ref);
					}else{
						ret = gtDecodeClassType(ref);
					}
				}
			case TAnonymous(a):
				var a = a.get();
				a.fields.sort((a,b) -> {
					return haxe.macro.Context.getPosInfos(a.pos).min - haxe.macro.Context.getPosInfos(b.pos).min;
				});
				var fields = [];
					for (field in a.fields) {
						fields.push(macro stdgo.reflect.Reflect.GT_enum.GT_field(field.name,gtDecode(field.type),""));
					}
				ret = macro stdgo.reflect.Reflect.GT_enum.GT_struct($a{fields});
			case TFun(a, result):
				var args = [];
				for (arg in a) {
					args.push(gtDecode(arg.t));
				}
				var results = []; //TODO handle multi return
				var isVoid = false;
				switch result {
					case TAbstract(t, params):
						if (t.toString() == "Void")
							isVoid = true;
					default:
				}
				if (!isVoid)
					results.push(gtDecode(result));
				ret = macro stdgo.reflect.Reflect.GT_enum.GT_func($a{args},$a{results});
			case TDynamic(t):
				ret = macro stdgo.reflect.Reflect.GT_enum.GT_interface(
					"","",
					"interface{}",
					[]
				);
			default:
				throw "reflect.cast_AnyInterface - unhandled typeof " + t;
		}
		return ret;
	}
	
	static function gtDecodeInterfaceType(ref:haxe.macro.Type.ClassType):Expr {
		var methods = [];
		for (method in ref.fields.get()) {
			methods.push(macro stdgo.reflect.Reflect.GT_enum.GT_field($v{method.name},${gtDecode(method.type)},""));
		}
		return macro stdgo.reflect.Reflect.GT_enum.GT_interface($v{ref.pack.join(".")},$v{ref.module},$v{ref.name},$a{methods});
	}
	
	static function gtDecodeClassType(ref:haxe.macro.Type.ClassType):Expr {
		var methods:Array<Expr> = [];
		var fields:Array<Expr> = [];
		var interfaces = [];
		if (ref.module == "String")
			return macro stdgo.reflect.Reflect.GT_enum.GT_string;
		for (inter in ref.interfaces) {
			var inter = inter.t.get();
			interfaces.push(gtDecodeInterfaceType(inter));
		}
		var fs = ref.fields.get();
		var module = parseModule(ref.module);
		for (field in fs) {
			switch field.kind {
				case FMethod(k):
					switch field.name {
						case "new", "__copy__":
							continue;
					}
					switch field.type {
						case TFun(args, ret):
							var params = [];
							var rets = [];
							for (arg in args) {
								params.push(gtDecode(arg.t));
							}
							switch ret {
								case TAnonymous(a):
									var fs = a.get().fields;
									for (f in fs) {
										rets.push(macro stdgo.reflect.Reflect.GT_enum.GT_field(f.name,gtDecode(f.type),""));
									}
								default:
									if (field.name == "toString") {
										switch ret {
											case TInst(t, params):
												var t = t.get();
												if (t.name == "String")
													continue;
											default:
										}
									}
									rets.push(gtDecode(ret));
							}
							params.unshift(macro stdgo.reflect.Reflect.GT_enum.GT_field("this", stdgo.reflect.Reflect.GT_enum.GT_previouslyNamed($v{module} + "." + $v{ref.name}),"")); //recv
							methods.push(macro stdgo.reflect.Reflect.GT_enum.GT_field($v{field.name}, stdgo.reflect.Reflect.GT_enum.GT_func($a{params},$a{rets}),""));
						default:
							throw "method needs to be a function";
					}
				default:
					if (field.name == "_address_")
						continue;
					var t = gtDecode(field.type);
					fields.push(macro stdgo.reflect.Reflect.GT_enum.GT_field($v{field.name},$t,""));
			}
		}
		var fields = macro $a{fields};
		var t = macro stdgo.reflect.Reflect.GT_enum.GT_struct($fields);
		return macro stdgo.reflect.Reflect.GT_enum.GT_namedType($v{ref.pack.join(".")},$v{module}, $v{ref.name},$a{methods}, $a{interfaces},$t);
	}
	#end

	public static macro function set(params:Array<Expr>) {
		var t = Context.follow(Context.getExpectedType());
		var ct = Context.toComplexType(t);
		var fields = [];
		switch t {
			case TAnonymous(a):
				fields = a.get().fields;
			case TInst(t, params2):
				fields = t.get().fields.get();
			default:
				throw "unknown set type: " + t;
		}
		for (i in 0...fields.length) {
			var ft = Context.toComplexType(fields[i].type);
			switch ft {
				case TPath(p):
					if (p.name == "StdGoTypes" && p.sub == "AnyInterface") {
						params[i] = macro Go.toInterface(${params[i]});
					}
				default:
			}
		}
		switch ct {
			case TPath(p):
				return macro new $p($a{params});
			case TFunction(args, ret):
				return macro null;
			case TAnonymous(fields):
				var anon = createAnonType(Context.currentPos(), fields, params);
				//trace(new haxe.macro.Printer().printExpr(anon));
				return anon;
			default:
				throw("unknown go set type: " + t);
		}
	}

	public static macro function setKeys(expr:Expr) {
		var t = Context.toComplexType(Context.getExpectedType());
		return macro($expr : $t);
	}

	public static macro function destruct(exprs:Array<Expr>) {
		var varNames:Array<String> = [];
		for (expr in exprs) {
			switch expr.expr {
				case EConst(c):
					switch c {
						case CString(s, kind):
							varNames.push(s);
						default:
					}
				default:
			}
		}
		var func = exprs.pop();
		var funcType = Context.followWithAbstracts(Context.typeof(func));
		var f = [];
		switch funcType {
			case TAnonymous(a):
				f = a.get().fields;
			case TInst(t, params):
				f = t.get().fields.get();
			default:
				throw "unknown funcType";
		}
		f.sort((a,b) -> {
			return Context.getPosInfos(a.pos).min - Context.getPosInfos(b.pos).min;
		});
		var fieldNames = [];
		for (i in 0...f.length) {
			fieldNames.push(f[i].name);
		}
		var tmp = macro var __tmp__ = $func;
		if (varNames.length > 0) {
			switch tmp.expr {
				case EVars(vars):
					for (i in 0...varNames.length) {
						var fieldName = fieldNames[i];
						vars.push({
							name: varNames[i],
							expr: macro __tmp__.$fieldName,
						});
					}
					return tmp;
				default:
					throw "tmp needs to be evars";
			}
		}else{
			var block:Array<Expr> = [tmp];
			for (i in 0...exprs.length) {
				var fieldName = fieldNames[i];
				block.push(macro ${exprs[i]} = __tmp__.$fieldName);
			}
			return macro $b{block};
		}
	}

	private static function parseModule(module:String):String {
		var index = module.lastIndexOf(".");
		var name = module.substr(index + 1);
		module = module.substr(0,index);
		module = module.substr(module.lastIndexOf(".") + 1);
		if (module == name.charAt(0).toLowerCase() + name.substr(1))
			module = "main";
		return module;
	}
}
