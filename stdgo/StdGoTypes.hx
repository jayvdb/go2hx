/*
 * Copyright (C)2005-2021 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package stdgo;

import stdgo.Pointer.PointerData;
import stdgo.StdGoTypes.AnyInterface;
import haxe.Int32;
import haxe.Int64;
//native_num define flag
typedef GoByte = GoUInt8;
typedef GoRune = GoInt;
typedef GoInt32 = GoInt;
typedef GoUInt32 = GoUInt;
typedef GoFloat64 = GoFloat;
private typedef Int = StdTypes.Int;
private typedef Int8 = #if !native_num Int #elseif cpp cpp.Int8 #elseif cs cs.Int8 #elseif java java.Int8 #else Int #end;
private typedef Int16 = #if !native_num Int #elseif cpp cpp.Int16 #elseif cs cs.Int16 #elseif java java.Int16 #else Int #end;
private typedef Int32 = haxe.Int32; // #if cpp cpp.Int32 #elseif cs cs.system.Int32 #else haxe.Int32 #end;
private typedef Int64 = haxe.Int64; // #if cpp cpp.Int64 #elseif cs cs.system.Int64 #elseif java java.Int64 #elseif eval eval.integers.Int64 #else haxe.Int64 #end;
private typedef UInt = Int;
private typedef UInt8 = Int;//#if hl hl.UI8 #elseif cpp cpp.UInt8 #elseif cs cs.UInt8 #else Int #end;
private typedef UInt16 = #if !native_num Int #elseif hl hl.UI16 #elseif cpp cpp.UInt16 #elseif cs cs.UInt16 #else Int #end;
private typedef UInt32 = #if !native_num Int #elseif cpp cpp.UInt32 #elseif cs cs.system.UInt32 #else Int #end;
private typedef UInt64 = #if !native_num Int64 #elseif cpp cpp.UInt64 #elseif eval eval.integers.UInt64 #else Int64 #end // __UInt64 #end;
private typedef Float = StdTypes.Float;
private typedef Float32 = #if !native_num Float #elseif (java || cs || hl || cpp) StdTypes.Single #else Float #end;
private typedef Float64 = #if !native_num Float #elseif cpp cpp.Float64 #else Float #end

private class __UInt64 {
	public var high:Int64;
	public var low:Int64;

	public inline function new(high, low) {
		this.high = high;
		this.low = low;
	}

	public static inline function ofInt(x:Int) {
		if (x < 0)
			return new __UInt64(0,0);
		return new __UInt64(x >> 31, x);
	}
}

private class __Int128 {
	public var high:Int64;
	public var low:Int64;
	public inline function new(high,low) {
		this.high = high;
		this.low = low;
	}
	public static inline function ofInt(x:Int) {
		return new __Int128(x >> 63, x);
	}
	public function toString():String
		return GoComplex128.toStr(cast this);
}
function clampInt8(x:Int):Int {
	var r = x & 0xFF;
	if ((r & 0x80) != 0) {
		return -1 - 0xFF + r;
	}
	return r;
}
function clampInt16(x:Int):Int {
	var r = x & 0xFFFF;
	if ((r & 0x8000) != 0) {
		return -1 - 0xFFFF + r;
	}
	return r;
}
function clampUInt8(x:Int):Int
	return x & 0xFF;
function clampUInt16(x:Int):Int
	return x & 0xFFFF;
//no clamp for UInt32 or UInt64 as they overflow into negative range



abstract GoUIntptr(UInt) from UInt {
	public inline function new(x=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public inline function _typeName_()
		return "uintptr";

	@:op(A + B) private static function add(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A * B) private static function mul(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A % B) private static function mod(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A - B) private static function sub(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A | B) private static function or(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A ^ B) private static function xor(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A & B) private static function and(a:GoUIntptr, b:GoUIntptr):GoUIntptr;

	@:op(A > B) private static function gt(a:GoUIntptr, b:GoUIntptr):Bool;

	@:op(A >= B) private static function gte(a:GoUIntptr, b:GoUIntptr):Bool;

	@:op(A < B) private static function lt(a:GoUIntptr, b:GoUIntptr):Bool;

	@:op(A <= B) private static function lte(a:GoUIntptr, b:GoUIntptr):Bool;

	@:op(~A) private static function bneg(t:GoUIntptr):GoUIntptr;


}

abstract GoFloat(Float) from Float {
	public inline function new(x=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public inline function _typeName_()
		return "float";



	@:op(A + B) private static function add(a:GoFloat, b:GoFloat):GoFloat;



	@:op(A * B) private static function mul(a:GoFloat, b:GoFloat):GoFloat;

	@:op(A % B) private static function modI(a:GoFloat, b:Int):GoFloat;

	@:op(A % B) private static function modF(a:GoFloat, b:Float):Float;

	@:op(A % B) private static function mod(a:GoFloat, b:GoFloat):GoFloat;

	@:op(A - B) private static function subI(a:GoFloat, b:Int):GoFloat;

	@:op(A - B) private static function subF(a:GoFloat, b:Float):Float;

	@:op(A - B) private static function sub(a:GoFloat, b:GoFloat):GoFloat;


	@:op(A | B) private static function or(a:GoFloat, b:GoFloat):GoFloat;


	@:op(A ^ B) private static function xor(a:GoFloat, b:GoFloat):GoFloat;


	@:op(A & B) private static function and(a:GoFloat, b:GoFloat):GoFloat;

	@:op(A << B) private static function shl(a:GoFloat, b:Int):GoFloat;

	@:op(A >> B) private static function shr(a:GoFloat, b:Int):GoFloat;

	@:op(A >>> B) private static function ushr(a:GoFloat, b:Int):GoFloat;

	@:op(A > B) private static function gt(a:GoFloat, b:GoFloat):Bool;

	@:op(A >= B) private static function gte(a:GoFloat, b:GoFloat):Bool;

	@:op(A < B) private static function lt(a:GoFloat, b:GoFloat):Bool;

	@:op(A <= B) private static function lte(a:GoFloat, b:GoFloat):Bool;

	@:op(A > B) private static function gtf(a:GoFloat, b:Float):Bool;

	@:op(A > B) private static function gtf2(a:Float, b:GoFloat):Bool;

	@:op(A >= B) private static function gtef(a:GoFloat, b:Float):Bool;

	@:op(A >= B) private static function gtef2(a:Float, b:GoFloat):Bool;

	@:op(A < B) private static function ltf(a:GoFloat, b:Float):Bool;

	@:op(A < B) private static function ltf2(a:Float, b:GoFloat):Bool;

	@:op(A <= B) private static function ltef(a:GoFloat, b:Float):Bool;

	@:op(A <= B) private static function ltef2(a:Float, b:GoFloat):Bool;

	@:op(~A) private static function bneg(t:GoFloat):GoFloat;




}

abstract GoFloat32(Float32) from Float32 {
	public inline function new(x=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public inline function _typeName_()
		return "float32";

	@:op(A > B) private static function gt(a:GoFloat32, b:GoFloat32):Bool;

	@:op(A >= B) private static function gte(a:GoFloat32, b:GoFloat32):Bool;

	@:op(A < B) private static function lt(a:GoFloat32, b:GoFloat32):Bool;

	@:op(A <= B) private static function lte(a:GoFloat32, b:GoFloat32):Bool;

	@:op(A > B) private static function gtf(a:GoFloat32, b:Float):Bool;

	@:op(A > B) private static function gtf2(a:Float, b:GoFloat32):Bool;

	@:op(A >= B) private static function gtef(a:GoFloat32, b:Float):Bool;

	@:op(A >= B) private static function gtef2(a:Float, b:GoFloat32):Bool;

	@:op(A < B) private static function ltf(a:GoFloat32, b:Float):Bool;

	@:op(A < B) private static function ltf2(a:Float, b:GoFloat32):Bool;

	@:op(A <= B) private static function ltef(a:GoFloat32, b:Float):Bool;

	@:op(A <= B) private static function ltef2(a:Float, b:GoFloat32):Bool;

	// TODO: Clamp Float32
}
abstract GoComplex64(Int64) from Int64 {
	public inline function new(x)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public static inline function ofInt(x:Int):GoComplex64 
		return new GoComplex64(Int64.make(x >> 31, x));

	public inline function _typeName_()
		return "complex64";

	@:op(A + B) private static function add(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() + b.toBasic();

	@:op(A * B) private static function mul(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() * b.toBasic();
	@:op(A / B) private static function div(a:GoComplex64,b:GoComplex64):GoComplex64
		return Int64.div(a.toBasic(),b.toBasic());

	@:op(A % B) private static function mod(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() % b.toBasic();

	@:op(A - B) private static function sub(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() - b.toBasic();

	@:op(A | B) private static function or(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() | b.toBasic();

	@:op(A ^ B) private static function xor(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() ^ b.toBasic();

	@:op(A & B) private static function and(a:GoComplex64, b:GoComplex64):GoComplex64
		return a.toBasic() & b.toBasic();

	@:op(A > B) private static function gt(a:GoComplex64, b:GoComplex64):Bool
		return a.toBasic() > b.toBasic();

	@:op(A >= B) private static function gte(a:GoComplex64, b:GoComplex64):Bool
		return a.toBasic() >= b.toBasic();

	@:op(A < B) private static function lt(a:GoComplex64, b:GoComplex64):Bool
		return a.toBasic() < b.toBasic();

	@:op(A <= B) private static function lte(a:GoComplex64, b:GoComplex64):Bool
		return a.toBasic() <= b.toBasic();
	@:op(~A) private static function bneg(t:GoComplex64):GoComplex64;

	@:op(A >> B) private static function shr(a:GoComplex64,b:GoComplex64):GoComplex64
		return a.toBasic() >> (b.toBasic().low : Int);
	@:op(A << B) private static function shl(a:GoComplex64,b:GoComplex64):GoComplex64
		return a.toBasic() << (b.toBasic().low : Int);

}
abstract GoComplex128(__Int128) from __Int128 {
	public inline function new(x)
		this = x;
	public inline function toBasic()
		return this;
	public inline function toInt()
		return Int64.toInt(low);
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public inline function _typeName_()
		return "complex128";

	public static inline function toStr(x:GoComplex128):String
		return x.toString();
	function toString():String {
		var i:GoComplex128 = cast this;
		if (i == ofInt(0))
			return "0";
		var str = "";
		var neg = false;
		if (i.isNeg())
			neg = true;
		var ten:GoComplex128 = ofInt(10);
		var zero = ofInt(0);
		while (i != zero) {
			var r = divMod(i,ten);
			if (r.modulus.isNeg()) {
				str = GoComplex128.neg(r.modulus).low + str;
				i = GoComplex128.neg(r.quotient);
			} else {
				str = r.modulus.low + str;
				i = r.quotient;
			}
		}
		if (neg)
			str = "-" + str;
		return str;
	}
	public function isNeg():Bool {
		return this.high < 0;
	}
	public static function divMod(dividend:GoComplex128, divisor:GoComplex128):{quotient:GoComplex128, modulus:GoComplex128} {
		// Handle special cases of 0 and 1
		if (divisor.high == 0) {
			if (divisor.low == 0) {
				throw "divide by zero";
			} else if (divisor.low == 1) {
				return {quotient: dividend.copy(), modulus: ofInt(0)};
			}
		}

		var divSign = dividend.isNeg() != divisor.isNeg();

		var modulus = dividend.isNeg() ? -dividend : dividend.copy();
		divisor = divisor.isNeg() ? -divisor : divisor;

		var quotient:GoComplex128 = ofInt(0);
		var mask:GoComplex128 = ofInt(1);

		while (!divisor.isNeg()) {
			var cmp = ucompare(divisor, modulus);
			divisor <<= GoComplex128.ofInt(1);
			mask <<= GoComplex128.ofInt(1);
			if (cmp >= 0)
				break;
		}
		var zero = ofInt(0);
		while (mask != zero) {
			if (ucompare(modulus, divisor) >= 0) {
				quotient |= mask;
				modulus -= divisor;
			}
			mask >>>= 1;
			divisor >>>= 1;
		}
		if (divSign)
			quotient = -quotient;
		if (dividend.isNeg())
			modulus = -modulus;

		return {
			quotient: quotient,
			modulus: modulus
		};
	}

	@:op(A * B)
	public static #if !lua inline #end function mul(a:GoComplex128, b:GoComplex128):GoComplex128 {
		var mask = 0xFFFF;
		var al = a.low & mask, ah = a.low >>> 16;
		var bl = b.low & mask, bh = b.low >>> 16;
		var p00 = al * bl;
		var p10 = ah * bl;
		var p01 = al * bh;
		var p11 = ah * bh;
		var low = p00;
		var high = p11 + (p01 >>> 16) + (p10 >>> 16);
		p01 <<= 16;
		low += p01;
		if (Int64.ucompare(low, p01) < 0)
			high++;
		p10 <<= 16;
		low += p10;
		if (Int64.ucompare(low, p10) < 0)
			high++;
		high += a.low * b.high + a.high * b.low;
		return make(high, low);
	}

	public static inline function compare(a:GoComplex128, b:GoComplex128):Int64 {
		var v = a.high - b.high;
		v = if (v != 0) v else Int64.ucompare(a.low, b.low);
		return a.high < 0 ? (b.high < 0 ? v : -1) : (b.high >= 0 ? v : 1);
	}
	public static inline function ucompare(a:GoComplex128,b:GoComplex128):Int64 {
		var v = Int64.compare(a.high,b.high);
		return if (v != 0) v else Int64.ucompare(a.low,b.low);
	}
	public inline function copy()
		return make(this.high.copy(),this.low.copy());
	public static inline function make(high:Int64,low:Int64):GoComplex128
		return new GoComplex128(new __Int128(high,low));
	public static inline function ofInt(x:Int):GoComplex128 {
		return make(x >> 63,x);
	}

	@:op(A == B) public static inline function eq(a:GoComplex128, b:GoComplex128):Bool
		return a.high == b.high && a.low == b.low;

	@:op(A != B) public static inline function neq(a:GoComplex128, b:GoComplex128):Bool {
		return a.high != b.high || a.low != b.low;
	}

	@:op(A < B) private static inline function lt(a:GoComplex128, b:GoComplex128):Bool
		return compare(a, b) < 0;

	@:op(A <= B) private static inline function lte(a:GoComplex128, b:GoComplex128):Bool
		return compare(a, b) <= 0;

	@:op(A > B) private static inline function gt(a:GoComplex128, b:GoComplex128):Bool
		return compare(a, b) > 0;

	@:op(A >= B) private static inline function gte(a:GoComplex128, b:GoComplex128):Bool
		return compare(a, b) >= 0;

	@:op(-A) public static inline function neg(x:GoComplex128):GoComplex128 {
		var high = ~x.high;
		var low = -x.low;
		if (low == 0)
			high++;
		return make(high, low);
	}
	@:op(~A) private static inline function complement(a:GoComplex128):GoComplex128
		return make(~a.high, ~a.low);

	@:op(A >> B) public static inline function shr(a:GoComplex128, b:GoComplex128):GoComplex128 {
		var b = b.toInt();
		b &= 127;
		return if (b == 0) a.copy() else if (b < 64) make(a.high >> b, (a.high << (64 - b)) | (a.low >>> b)); else make(a.high >> 63, a.high >> (b - 64));
	}
	@:op(A ^ B) public static inline function xor(a:GoComplex128, b:GoComplex128):GoComplex128
		return make(a.high ^ b.high, a.low ^ b.low);

	@:op(A << B) public static inline function shl(a:GoComplex128, b:GoComplex128):GoComplex128 {
		var b = b.toInt();
		b &= 127;
		return if (b == 0) a.copy() else if (b < 64) make((a.high << b) | (a.low >>> (64 - b)), a.low << b) else make(a.low << (b - 64), 0);
	}

	@:op(A & B) public static inline function and(a:GoComplex128, b:GoComplex128):GoComplex128
		return make(a.high & b.high, a.low & b.low);
	@:op(A | B) public static inline function or(a:GoComplex128, b:GoComplex128):GoComplex128
		return make(a.high | b.high, a.low | b.low);
	@:op(A >>> B) public static inline function ushr(a:GoComplex128, b:Int):GoComplex128 {
		b &= 127;
		return if (b == 0) a.copy() else if (b < 64) make(a.high >>> b, (a.high << (64 - b)) | (a.low >>> b)); else make(0, a.high >>> (b - 64));
	}
	@:op(A + B) public static inline function add(a:GoComplex128, b:GoComplex128):GoComplex128 {
		var high = a.high + b.high;
		var low = a.low + b.low;
		if (Int64.ucompare(low, a.low) < 0)
			high++;
		return make(high, low);
	}
	@:op(A - B) public static inline function sub(a:GoComplex128, b:GoComplex128):GoComplex128 {
		var high = a.high - b.high;
		var low = a.low - b.low;
		if (Int64.ucompare(a.low, b.low) < 0)
			high--;
		return make(high, low);
	}
	@:op(A % B) public static inline function mod(a:GoComplex128,b:GoComplex128):GoComplex128
		return divMod(a,b).modulus;
	@:op(A / B) public static inline function div(a:GoComplex128,b:GoComplex128):GoComplex128
		return divMod(a,b).quotient;

	public var high(get, never):Int64;

	private inline function get_high()
		return this.high;

	private inline function set_high(x)
		return this.high = x;

	public var low(get, never):Int64;

	private inline function get_low()
		return this.low;

	private inline function set_low(x)
		return this.low = x;
	public static function parseString(sParam:String):GoComplex128 {
		var base = GoComplex128.ofInt(10);
		var current = GoComplex128.ofInt(0);
		var multiplier = GoComplex128.ofInt(1);
		var sIsNegative = false;

		var s = StringTools.trim(sParam);
		if (s.charAt(0) == "-") {
			sIsNegative = true;
			s = s.substring(1, s.length);
		}
		var len = s.length;

		for (i in 0...len) {
			var digitInt = s.charCodeAt(len - 1 - i) - '0'.code;

			if (digitInt < 0 || digitInt > 9) {
				throw "NumberFormatError";
			}

			if (digitInt != 0) {
				var digit:GoComplex128 = GoComplex128.ofInt(digitInt);
				if (sIsNegative) {
					current = GoComplex128.sub(current, GoComplex128.mul(multiplier, digit));
					if (!current.isNeg()) {
						throw "NumberFormatError: Underflow";
					}
				} else {
					current = GoComplex128.add(current, GoComplex128.mul(multiplier, digit));
					if (current.isNeg()) {
						throw "NumberFormatError: Overflow";
					}
				}
			}

			multiplier = GoComplex128.mul(multiplier, base);
		}
		return current;
	}
}

abstract GoInt(Int) from Int32 {
	public inline function new(x:Int32=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public inline function _typeName_()
		return "int";

	public static function ofInt(x:Int):GoInt
		return x;

	@:op(A + B) private static function add(a:GoInt, b:GoInt):GoInt;

	@:op(A / B) private static function div(a:GoInt,b:GoInt):GoInt
		return Std.int(a.toBasic() / b.toBasic());

	@:op(A * B) private static function mul(a:GoInt, b:GoInt):GoInt;

	@:op(A % B) private static function mod(a:GoInt, b:GoInt):GoInt;

	@:op(A - B) private static function sub(a:GoInt, b:GoInt):GoInt;


	@:op(A | B) private static function or(a:GoInt, b:GoInt):GoInt;


	@:op(A ^ B) private static function xor(a:GoInt, b:GoInt):GoInt;


	@:op(A & B) private static function and(a:GoInt, b:GoInt):GoInt;

	@:op(A >> B) private static function shr(a:GoInt,b:GoInt):GoInt
		return a.toBasic() >> b.toBasic();
	@:op(A << B) private static function shl(a:GoInt,b:GoInt):GoInt
		return a.toBasic() << b.toBasic();
	@:op(A >>> B) private static function ushr(a:GoInt,b:GoInt):GoInt
		return a.toBasic() << b.toBasic();

	@:op(A > B) private static function gt(a:GoInt, b:GoInt):Bool;

	@:op(A >= B) private static function gte(a:GoInt, b:GoInt):Bool;

	@:op(A < B) private static function lt(a:GoInt, b:GoInt):Bool;

	@:op(A <= B) private static function lte(a:GoInt, b:GoInt):Bool;

	@:op(A > B) private static function gtf(a:GoInt, b:Float):Bool;

	@:op(A > B) private static function gtf2(a:Float, b:GoInt):Bool;

	@:op(A >= B) private static function gtef(a:GoInt, b:Float):Bool;

	@:op(A >= B) private static function gtef2(a:Float, b:GoInt):Bool;

	@:op(A < B) private static function ltf(a:GoInt, b:Float):Bool;

	@:op(A < B) private static function ltf2(a:Float, b:GoInt):Bool;

	@:op(A <= B) private static function ltef(a:GoInt, b:Float):Bool;

	@:op(A <= B) private static function ltef2(a:Float, b:GoInt):Bool;

	@:op(~A) private static function bneg(t:GoInt):GoInt;




}

abstract GoUInt(Int) from Int {
	public inline function new(x=0)
		this = x;

	public inline function toBasic()
		return this;

	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public inline function _typeName_()
		return "uint";

	public static function ofInt(x:Int):GoUInt
		return x;
	@:op(A + B) private static function add(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() + b.toBasic();
	@:op(A - B) private static function sub(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() - b.toBasic();
	@:op(A * B) private static function mul(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() * b.toBasic();
	@:op(A & B) private static function and(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() & b.toBasic();
	@:op(A | B) private static function or(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() | b.toBasic();
	@:op(A ^ B) private static function xor(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() ^ b.toBasic();
	@:op(A % B) private static function mod(a:GoUInt,b:GoUInt):GoUInt
		return a.toBasic() % b.toBasic();
	@:op(A / B) private static function div(a:GoUInt,b:GoUInt):GoUInt
		return Std.int(a.toBasic() / b.toBasic());


	@:op(A > B) private static function gt(a:GoUInt, b:GoUInt):Bool;

	@:op(A >= B) private static function gte(a:GoUInt, b:GoUInt):Bool;

	@:op(A < B) private static function lt(a:GoUInt, b:GoUInt):Bool;

	@:op(A <= B) private static function lte(a:GoUInt, b:GoUInt):Bool;

	@:op(A > B) private static function gtf(a:GoUInt, b:Float):Bool;

	@:op(A > B) private static function gtf2(a:Float, b:GoUInt):Bool;

	@:op(A >= B) private static function gtef(a:GoUInt, b:Float):Bool;

	@:op(A >= B) private static function gtef2(a:Float, b:GoUInt):Bool;

	@:op(A < B) private static function ltf(a:GoUInt, b:Float):Bool;

	@:op(A < B) private static function ltf2(a:Float, b:GoUInt):Bool;

	@:op(A <= B) private static function ltef(a:GoUInt, b:Float):Bool;

	@:op(A <= B) private static function ltef2(a:Float, b:GoUInt):Bool;
}

abstract GoInt8(Int8) from Int8 {
	public inline function new(x=0)
		this = x;

	public inline function toBasic()
		return this;

	public static function ofInt(x:Int):GoInt8
		return x;

	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public inline function _typeName_()
		return "int8";

	@:op(A > B) private static function gt(a:GoInt8, b:GoInt8):Bool;

	@:op(A >= B) private static function gte(a:GoInt8, b:GoInt8):Bool;

	@:op(A < B) private static function lt(a:GoInt8, b:GoInt8):Bool;

	@:op(A <= B) private static function lte(a:GoInt8, b:GoInt8):Bool;

	@:op(A >> B) private static function shr(a:GoInt8,b:GoInt8):GoInt8
		return clamp(a.toBasic() >> b.toBasic()); 
	@:op(A << B) private static function shl(a:GoInt8,b:GoInt8):GoInt8
		return clamp(a.toBasic() << b.toBasic());
	@:op(A >>> B) private static function ushr(a:GoInt8,b:GoInt8):GoInt8
		return clamp(a.toBasic() << b.toBasic());

	@:op(A + B) private static function add(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() + b.toBasic()));
	@:op(A - B) private static function sub(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() - b.toBasic()));
	@:op(A * B) private static function mul(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() - b.toBasic()));
	@:op(A & B) private static function and(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() & b.toBasic()));
	@:op(A | B) private static function or(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() | b.toBasic()));
	@:op(A ^ B) private static function xor(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() ^ b.toBasic()));
	@:op(A % B) private static function mod(a:GoInt8,b:GoInt8):GoInt8
		return clamp(Std.int(a.toBasic() % b.toBasic()));

	@:op(A > B) private static function gt(a:GoInt8,b:GoInt8):Bool
		return a.toBasic() > b.toBasic();
	@:op(A >= B) private static function gte(a:GoInt8,b:GoInt8):Bool
		return a.toBasic() >= b.toBasic();
	@:op(A < B) private static function lt(a:GoInt8,b:GoInt8):Bool
		return a.toBasic() < b.toBasic();
	@:op(A <= B) private static function lte(a:GoInt8,b:GoInt8):Bool
		return a.toBasic() <= b.toBasic();

	@:op(A / B) private static function div(a:GoInt8,b:GoInt8):GoInt8
		return Std.int(a.toBasic() / b.toBasic());
	// TODO: clamp int8
	static function clamp(x:Int)
		return clampInt8(x);
}

abstract GoInt16(Int16) from Int16 {
	public inline function new(x=0)
		this = x;

	public inline function toBasic()
		return this;

	public static function ofInt(x:Int):GoInt16
		return x;

	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public inline function _typeName_()
		return "int16";

	@:op(A > B) private static function gt(a:GoInt16, b:GoInt16):Bool;

	@:op(A >= B) private static function gte(a:GoInt16, b:GoInt16):Bool;

	@:op(A < B) private static function lt(a:GoInt16, b:GoInt16):Bool;

	@:op(A <= B) private static function lte(a:GoInt16, b:GoInt16):Bool;

	@:op(A > B) private static function gtf(a:GoInt16, b:Float):Bool;

	@:op(A > B) private static function gtf2(a:Float, b:GoInt16):Bool;

	@:op(A >= B) private static function gtef(a:GoInt16, b:Float):Bool;

	@:op(A >= B) private static function gtef2(a:Float, b:GoInt16):Bool;

	@:op(A < B) private static function ltf(a:GoInt16, b:Float):Bool;

	@:op(A < B) private static function ltf2(a:Float, b:GoInt16):Bool;

	@:op(A <= B) private static function ltef(a:GoInt16, b:Float):Bool;

	@:op(A <= B) private static function ltef2(a:Float, b:GoInt16):Bool;
	
	@:op(A >> B) private static function shr(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() >> b.toBasic());
	@:op(A << B) private static function shl(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() << b.toBasic());
	@:op(A >>> B) private static function ushr(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() << b.toBasic());

	@:op(A + B) private static function add(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() + b.toBasic());
	@:op(A - B) private static function sub(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() - b.toBasic());
	@:op(A * B) private static function mul(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() * b.toBasic());
	@:op(A & B) private static function and(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() & b.toBasic());
	@:op(A | B) private static function or(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() | b.toBasic());
	@:op(A ^ B) private static function xor(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() ^ b.toBasic());
	@:op(A % B) private static function mod(a:GoInt16,b:GoInt16):GoInt16
		return clamp(a.toBasic() % b.toBasic());
	@:op(A / B) private static function div(a:GoInt16,b:GoInt16):GoInt16
		return Std.int(a.toBasic() / b.toBasic());

	@:op(A > B) private static function gt(a:GoInt16,b:GoInt16):Bool
		return a.toBasic() > b.toBasic();
	@:op(A >= B) private static function gte(a:GoInt16,b:GoInt16):Bool
		return a.toBasic() >= b.toBasic();
	@:op(A < B) private static function lt(a:GoInt16,b:GoInt16):Bool
		return a.toBasic() < b.toBasic();
	@:op(A <= B) private static function lte(a:GoInt16,b:GoInt16):Bool
		return a.toBasic() <= b.toBasic();
	static function clamp(x:Int):Int
		return clampInt16(x);
}

abstract IntegerType(Int64) from Int64 {
	public inline function new(x) {
		this = x;
	}
	function toString():String
		return Std.string(this);
	function toBasic():Int64
		return this;

	@:from private static function fromString(x:String):IntegerType
		return Int64.parseString(x);
	@:from private static function fromInt(x:Int):IntegerType
		return Int64.ofInt(x);
	@:to function toInt():GoInt
		return Int64.toInt(this);
	@:to function toInt8():GoInt8
		return clampInt8(Int64.toInt(this));
	@:to function toInt16():GoInt16
		return clampInt16(Int64.toInt(this));
	@:to function toInt64():GoInt64
		return this;
	@:to function toUInt():GoUInt {
		var i = this;
		if (i.high > 0)
			return i.high - i.low;
		return Int64.toInt(i);
	}
	@:to function toUInt8():GoUInt8
		return clampUInt8(Int64.toInt(this));
	@:to function toUInt16():GoUInt16
		return clampUInt16(Int64.toInt(this));
	@:to function toUInt64():GoUInt64
		return this; //when processed from string -> int64 should flow into negative range in order to fill

	@:op(A * B) private static function mul(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A / B) private static function div(a:IntegerType,b:IntegerType):IntegerType
		return Int64.div(a.toBasic(),b.toBasic());
	@:op(A - B) private static function sub(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A + B) private static function add(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A & B) private static function and(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A | B) private static function or(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A ^ B) private static function xor(a:IntegerType,b:IntegerType):IntegerType
		return a.toBasic() ^ b.toBasic();
	@:op(A % B) private static function mod(a:IntegerType,b:IntegerType):IntegerType;

	@:op(A > B) private static function gt(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A >= B) private static function gte(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A < B) private static function lt(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A <= B) private static function lte(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A == B) private static function equal(a:IntegerType,b:IntegerType):IntegerType;
	@:op(A != B) private static function neq(a:IntegerType,b:IntegerType):IntegerType;

	@:op(A << B) private static function shl(a:IntegerType,b:IntegerType):IntegerType
		return a.toBasic() << Int64.toInt(b.toBasic());
	@:op(A >> B) private static function shr(a:IntegerType,b:IntegerType):IntegerType
		return a.toBasic() >> Int64.toInt(b.toBasic());
	@:op(A >>> B) private static function ushr(a:IntegerType,b:IntegerType):IntegerType;

	@:op(~A) private static function neg(a:IntegerType):IntegerType;
	@:op(++A) private static function preInc(a:IntegerType):IntegerType;
	@:op(A++) private static function postInc(a:IntegerType):IntegerType;
	@:op(--A) private static function preDec(a:IntegerType):IntegerType;
	@:op(A--) private static function postDec(a:IntegerType):IntegerType;
}

abstract GoInt64(Int64) from Int64 {
	public inline function new(x)
		this = x;
	public inline function toBasic()
		return this;

	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	function toString()
		return haxe.Int64.toStr(this);

	public inline function _typeName_()
		return "int64";

	public static inline function ofInt(x:Int):GoInt64
		return (Int64.make(x >> 31, x) : GoInt64);

	@:op(A >> B) private static function shr(a:GoInt64,b:GoInt64):GoInt64
		return a.toBasic() >> (b.toBasic().low : Int);
	@:op(A << B) private static function shl(a:GoInt64,b:GoInt64):GoInt64
		return a.toBasic() << (b.toBasic().low : Int);

	@:op(A + B) public static function add(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() + b.toBasic();

	@:op(A * B) public static function mul(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() * b.toBasic();

	@:op(A % B) public static function mod(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() % b.toBasic();

	@:op(A / B) public static function div(a:GoInt64, b:GoInt64):GoInt64
		return Int64.div(a.toBasic(),b.toBasic());

	@:op(A - B) public static function sub(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() - b.toBasic();

	@:op(A | B) public static function or(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() | b.toBasic();

	@:op(A ^ B) public static function xor(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() ^ b.toBasic();

	@:op(A & B) public static function and(a:GoInt64, b:GoInt64):GoInt64
		return a.toBasic() & b.toBasic();

	@:op(A > B) private static function gt(a:GoInt64, b:GoInt64):Bool
		return a.toBasic() > b.toBasic();

	@:op(A >= B) private static function gte(a:GoInt64, b:GoInt64):Bool
		return a.toBasic() >= b.toBasic();

	@:op(A < B) private static function lt(a:GoInt64, b:GoInt64):Bool
		return a.toBasic() < b.toBasic();

	@:op(A <= B) private static function lte(a:GoInt64, b:GoInt64):Bool
		return a.toBasic() <= b.toBasic();

	@:op(~A) private static function bneg(t:GoInt64):GoInt64;

	@:op(A == B) private static function equals(a:GoInt64,b:GoInt64):Bool
		return Int64.eq(a.toBasic(),b.toBasic());
	@:op(A != B) private static function notEquals(a:GoInt64,b:GoInt64):Bool
		return Int64.neq(a.toBasic(),b.toBasic());
}

abstract GoUInt8(UInt8) from UInt8 {
	public inline function new(x=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});
	public static inline function ofInt(x:Int)
		return x;
	public inline function _typeName_()
		return "uint8";

	@:op(A > B) private static function gt(a:GoUInt8, b:GoUInt8):Bool;

	@:op(A >= B) private static function gte(a:GoUInt8, b:GoUInt8):Bool;

	@:op(A < B) private static function lt(a:GoUInt8, b:GoUInt8):Bool;

	@:op(A <= B) private static function lte(a:GoUInt8, b:GoUInt8):Bool;

	
@:op(A + B) private static function add(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() + b.toBasic());
@:op(A - B) private static function sub(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() - b.toBasic());
@:op(A * B) private static function mul(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() * b.toBasic());
@:op(A & B) private static function and(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() & b.toBasic());
@:op(A | B) private static function or(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() | b.toBasic());
@:op(A ^ B) private static function xor(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() ^ b.toBasic());
@:op(A % B) private static function mod(a:GoUInt8,b:GoUInt8):GoUInt8
	return clamp(a.toBasic() % b.toBasic());
@:op(A / B) private static function div(a:GoUInt8,b:GoUInt8):GoUInt8
    return clamp(Std.int(a.toBasic() / b.toBasic()));

	@:op(A << B) private static function shl(a:GoUInt8, b:GoUInt8):GoUInt8
		return clamp(a.toBasic() << b.toBasic());

	@:op(A >> B) private static function shr(a:GoUInt8, b:GoUInt8):GoUInt8
		return clamp(a.toBasic() << b.toBasic());
	// TODO: clamp uint8
	static function clamp(x:Int)
		return clampUInt8(x);
}

abstract GoUInt16(UInt16) from UInt16 {
	public inline function new(x=0)
		this = x;
	public inline function toBasic()
		return this;
	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public static function ofInt(x:Int):GoUInt16
		return x;

	public inline function _typeName_()
		return "uint16";

	@:op(A > B) private static function gt(a:GoUInt16, b:GoUInt16):Bool;

	@:op(A >= B) private static function gte(a:GoUInt16, b:GoUInt16):Bool;

	@:op(A < B) private static function lt(a:GoUInt16, b:GoUInt16):Bool;

	@:op(A <= B) private static function lte(a:GoUInt16, b:GoUInt16):Bool;

	@:op(A >> B) private static function shr(a:GoUInt16,b:GoUInt16):GoUInt16
		return a.toBasic() >> b.toBasic();
	@:op(A << B) private static function shl(a:GoUInt16,b:GoUInt16):GoUInt16
		return a.toBasic() << b.toBasic();

	
@:op(A + B) private static function add(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() + b.toBasic());
@:op(A - B) private static function sub(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() - b.toBasic());
@:op(A * B) private static function mul(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() * b.toBasic());
@:op(A & B) private static function and(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() & b.toBasic());
@:op(A | B) private static function or(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() | b.toBasic());
@:op(A ^ B) private static function xor(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() ^ b.toBasic());
@:op(A % B) private static function mod(a:GoUInt16,b:GoUInt16):GoUInt16
	return clamp(a.toBasic() % b.toBasic());
@:op(A / B) private static function div(a:GoUInt16,b:GoUInt16):GoUInt16
    return Std.int(a.toBasic() / b.toBasic());
	static function clamp(x:Int)
		return clampUInt16(x);
}

abstract GoUInt64(UInt64) from UInt64 {
	public inline function new(x)
		this = x;
	public inline function toBasic()
		return this;

	@:to inline function __promote()
		return new AnyInterface({value: this, typeName: _typeName_()});

	public inline function _typeName_()
		return "uint64";

	@:from public static inline function ofString(x:String):GoUInt64
		return UInt64.parseString(x);
	@:from public static inline function ofInt(x:Int):GoUInt64
		return UInt64.ofInt(x);
	@:from public static inline function ofFloat(x:Float):GoUInt64
		return (Std.int(x) : GoUInt64);

	@:op(A > B) private static function gt(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() > b.toBasic();

	@:op(A >= B) private static function gte(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() >= b.toBasic();

	@:op(A < B) private static function lt(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() < b.toBasic();

	@:op(A <= B) private static function lte(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() <= b.toBasic();

	@:op(A << B) private static function shl(a:GoUInt64, b:GoUInt64):GoUInt64
		return a.toBasic() << (b.toBasic().low : Int);
	@:op(A >> B) private static function shr(a:GoUInt64, b:GoUInt64):GoUInt64
		return a.toBasic() >> (b.toBasic().low : Int);

	@:op(A != B) private static function neq(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() != b.toBasic();

	@:op(A == B) private static function equals(a:GoUInt64, b:GoUInt64):Bool
		return a.toBasic() == b.toBasic();

	
@:op(A + B) private static function add(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() + b.toBasic();
@:op(A - B) private static function sub(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() - b.toBasic();
@:op(A * B) private static function mul(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() * b.toBasic();
@:op(A & B) private static function and(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() & b.toBasic();
@:op(A | B) private static function or(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() | b.toBasic();
@:op(A ^ B) private static function xor(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() ^ b.toBasic();
@:op(A % B) private static function mod(a:GoUInt64,b:GoUInt64):GoUInt64
	return a.toBasic() % b.toBasic();
@:op(A / B) private static function div(a:GoUInt64,b:GoUInt64):GoUInt64
    return Int64.div(a.toBasic(), b.toBasic());
}
interface StructType {
	public final _typeName_:String;
	public var _address_:Int;
	public var _is_pointer_:Bool;
}
interface Error {
	public function error():String;
}

abstract AnyInterface({value:Any, typeName:String}) {
	public inline function new(obj=null) {
		this = obj;
	}

	@:to private inline function to<T>() {
		return (this.value : T);
	}

	@:from private static inline function from<T>(x:T) {
		if (x == null)
			return new AnyInterface({value: null,typeName: "null"});
		return new AnyInterface({value: x, typeName: "unknown"});
	}

	public inline function typeName() {
		return this.typeName;
	}

	public inline function value() {
		return this.value;
	}
}

interface ArrayAccess<T> {
	function get(i:Int):T;
	function set(i:Int, value:T):T;
}

interface MapAccess<K, V> {
	function get(k:K):Null<V>;
	function set(k:K, v:V):Void;
}
/*
	uint8       the set of all unsigned  8-bit integers (0 to 255)
	uint16      the set of all unsigned 16-bit integers (0 to 65535)
	uint32      the set of all unsigned 32-bit integers (0 to 4294967295)
	uint64      the set of all unsigned 64-bit integers (0 to 18446744073709551615)

	int8        the set of all signed  8-bit integers (-128 to 127)
	int16       the set of all signed 16-bit integers (-32768 to 32767)
	int32       the set of all signed 32-bit integers (-2147483648 to 2147483647)
	int64       the set of all signed 64-bit integers (-9223372036854775808 to 9223372036854775807)

	float32     the set of all IEEE-754 32-bit floating-point numbers
	float64     the set of all IEEE-754 64-bit floating-point numbers

	complex64   the set of all complex numbers with float32 real and imaginary parts
	complex128  the set of all complex numbers with float64 real and imaginary parts

	byte        alias for uint8
	rune        alias for int32
 */