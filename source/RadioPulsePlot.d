/**
 * @defgroup   RADIOPULSEPLOT Radio Pulse Plot
 *
 * @brief      This file implements RadioPulsePlot widget.
 *
 * @author     KonstantIMP
 * @date       2020
 */
module RadioPulsePlot;

import cairo.c.types;
import gtk.c.types;

import gtk.DrawingArea;
import gtk.Widget;

import cairo.Context;

import std.conv;
import std.math;

/// @brief      This class describes a rgba color
struct RgbaColor {
    /// @brief Amount of red 
    double r;
    /// @brief Amount of green
    double g;
    /// @brief Amount of blue
    double b;
    /// @brief Amount of alpha chanell
    double a;
}

enum modType {
    frecuency_mod,
    phase_mod
}

class RadioPulsePlot : DrawingArea {
    public this() @trusted { super();        
        reset(); addOnDraw(&onDraw);
    }

    public void reset() @safe {
        f_width = 20; mod_type = modType.frecuency_mod; 
        bit_sequence = ""; frequency = 100; time_discrete = 0.01;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
    }

    protected bool onDraw(Scoped!Context _context, Widget _widget) {
        _widget.setSizeRequest(0, 0);

        GtkAllocation _w_alloc;
        _widget.getAllocation(_w_alloc);

        int actual_size = f_width;

        if(bit_sequence.length != 0) {
            actual_size = cast(int)(f_width * cast(double)(time_discrete * frequency));
            if(actual_size < f_width) actual_size = f_width;

            _widget.setSizeRequest(cast(int)(actual_size * bit_sequence.length + 65), _w_alloc.height);
        } _widget.getAllocation(_w_alloc);        

        /// Drawing background color
        _context.setSourceRgba(background_color.r,
                               background_color.g,
                               background_color.b,
                               background_color.a);
        _context.paint(); _context.setLineWidth(2);

        /// Drawing axes
        _context.setSourceRgba(axes_color.r,
                               axes_color.g,
                               axes_color.b,
                               axes_color.a);
        /// Drawing X axis
        _context.moveTo(10, _w_alloc.height / 2);
        _context.relLineTo(_w_alloc.width - 20, 0);
        _context.relLineTo(-5, 2); _context.relLineTo(5, -2);
        _context.relLineTo(-5, -2); _context.relLineTo(5, 2);
        _context.stroke();
        /// Drawing Y axis
        _context.moveTo(20, _w_alloc.height - 10); _context.lineTo(20, 10);
        _context.relLineTo(2, 5); _context.relLineTo(-2, -5);
        _context.relLineTo(-2, 5); _context.relLineTo(2, -5);
        _context.stroke();
        /// Drawing +1V value
        _context.moveTo(16, _w_alloc.height / 6);
        _context.relLineTo(8, 0); _context.stroke();
        /// Drawing -1V value
        _context.moveTo(16, _w_alloc.height / 6 * 5);
        _context.relLineTo(8, 0); _context.stroke();
        /// Drawing X values
        _context.moveTo(20 + actual_size, _w_alloc.height / 2 - 4);
        _context.relLineTo(0, 8);
        if(bit_sequence.length != 0) {
            for(int i = 0; i < bit_sequence.length - 1; i++) {
                _context.relMoveTo(actual_size, -8);
                _context.relLineTo(0, 8);
            }
        }  _context.stroke();

        /// Making inscriptions
        cairo_text_extents_t extents;
        /// Plot name
        _context.setFontSize(12); _context.textExtents("График радиоканала", &extents);
        _context.moveTo(_w_alloc.width - 5 - extents.width, 12);
        _context.showText("График радиоканала");
        /// X axis name
        _context.setFontSize(10);
        _context.moveTo(_w_alloc.width - 35, _w_alloc.height / 2 + 12);
        _context.showText("t(сек.)");
        /// Y axis name
        _context.setFontSize(10);
        _context.moveTo(5, 10); _context.showText("А");
        ///_context.moveTo(3, 20); _context.showText("(В)");
        /// Y 1V value
        _context.moveTo(5, _w_alloc.height / 6 + 3);
        _context.showText("1");
        /// Y -1V value
        _context.moveTo(5, _w_alloc.height / 6 * 5 + 3);
        _context.showText("-1");
        /// X values drawing
        _context.rotate(3.1415 / 2); _context.setFontSize(9);
        _context.moveTo(_w_alloc.height / 2 + 6, 3 - (20 + actual_size));
        _context.showText(to!string(time_discrete));
        if(bit_sequence.length != 0) {
            for(int i = 0; i < bit_sequence.length - 1; i++) {
                _context.moveTo(_w_alloc.height / 2 + 6, 3 - 20 - actual_size * (i + 2));
                _context.showText(to!string(time_discrete * (i + 2)));
            }
        }

        /// Drawing plot line
        _context.rotate(- 3.1415 / 2); _context.setLineWidth(2);
        if(bit_sequence.length != 0) {
            _context.setLineWidth(1);
            _context.moveTo(20, _w_alloc.height / 2);
            _context.setSourceRgba(line_color.r,
                                   line_color.g,
                                   line_color.b,
                                   line_color.a);

            bool last_state = true;  uint need_draw;
            need_draw = cast(uint)(round(time_discrete * frequency));

            if(mod_type == modType.phase_mod) {
                for(size_t i = 0; i < bit_sequence.length; i++) {
                    double line_height;

                    if(bit_sequence[i] == '1') line_height = cast(double)(_w_alloc.height / 3);
                    else line_height = cast(double)(_w_alloc.height / 6);

                    line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4; 

                    for(int j = 0; j < need_draw * 2; j++) {
                        _context.relLineTo(0, line_height * (last_state == true ? -1 : 1));

                        double cur_x, cur_y; _context.getCurrentPoint(cur_x, cur_y);
                        if(last_state)
                            _context.arc(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);
                        else 
                            _context.arcNegative(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);

                        _context.relLineTo(0, line_height * (last_state == true ? 1 : -1));
                        last_state = !last_state;
                    }
                }
            }
            else {
                double line_height = cast(double)(_w_alloc.height / 3);
                line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4;

                for(size_t i = 0; i < bit_sequence.length; i++) {
                    if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

                    for(int j = 0; j < need_draw * 2; j++) {
                        _context.relLineTo(0, line_height * (last_state == true ? -1 : 1));

                        double cur_x, cur_y; _context.getCurrentPoint(cur_x, cur_y);
                        if(last_state)
                            _context.arc(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);
                        else 
                            _context.arcNegative(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);

                        _context.relLineTo(0, line_height * (last_state == true ? 1 : -1));
                        last_state = !last_state;
                    }
                }

            } _context.stroke();
        }

        return true;
    }

    public void drawRequest() @trusted {
        setSizeRequest(0, 0);
        queueDraw();
    }

    private ubyte f_width;
    @property ubyte FWidth() { return f_width; }
    @property ubyte FWidth(ubyte f) { return f_width = f; }

    private string bit_sequence; 
    @property string BitSequence() { return bit_sequence; }
    @property string BitSequence(string bits) { return bit_sequence = bits; }

    private uint frequency;
    @property uint Frequency() { return frequency; }
    @property uint Frequency(uint fr) { return frequency = fr; } 

    private double time_discrete;
    @property double TimeDiscrete() { return time_discrete; }
    @property double TimeDiscrete(double dis) { return time_discrete = dis; } 

    private modType mod_type;
    @property modType ModType() { return mod_type; }
    @property modType ModType(modType mt) { return mod_type = mt; }

    private RgbaColor line_color;
    @property RgbaColor LineColor() { return line_color; }
    @property RgbaColor LineColor(RgbaColor line_c) { return line_color = line_c; }

    private RgbaColor axes_color;
    @property RgbaColor AxesColor() { return background_color; }
    @property RgbaColor AxesColor(RgbaColor axes_c) { return axes_color = axes_c; }

    private RgbaColor background_color;
    @property RgbaColor BackgroundColor() { return background_color; }
    @property RgbaColor BackgroundColor(RgbaColor back_c) { return background_color = back_c; }
}