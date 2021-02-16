/// @file   Color.d
/// 
/// @brief  RgbaColor struct description
///
/// @license LGPLv3 (see LICENSE file)
/// @author KonstantIMP
/// @date   2020
module Color;

import std.string;
import std.conv;

/// @brief  RgbaColor   Struct to describe pixel color using RGBA color space
struct RgbaColor {
    /// @brief  r   Amount of red chanel in color
    double r;
    /// @brief  g   Amount of green chanel in color
    double g;
    /// @brief  b   Amount of blue chanel in color
    double b;
    /// @brief  a   Amount of alpha chanel in color
    double a;
}

/// @brief Function for converting RGBA color to a hex str
string rgbaToHexStr(immutable RgbaColor source) @safe {
    return rightJustify(to!string(toChars!16(cast(uint)(source.r * 255))), 2, '0') ~
           rightJustify(to!string(toChars!16(cast(uint)(source.g * 255))), 2, '0') ~
           rightJustify(to!string(toChars!16(cast(uint)(source.b * 255))), 2, '0') ~
           rightJustify(to!string(toChars!16(cast(uint)(source.a * 255))), 2, '0');
}