/**
 * @file VideoPulsePlot.d
 *
 * @brief      This file implements VideoPulsePlot widget.
 *
 * @author     KonstantIMP
 * @date       2020
 */
module VideoPulsePlot;

import cairo.c.types;
import gtk.c.types;

import gtk.DrawingArea;
import gtk.Widget;

import cairo.Context;

import std.conv;

/// @brief This class describes a rgba color
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

/**
 * @brief This class describes a VideoPulsePlot widget for GtkD.
 * 
 * It has two axes : Time and Voltage level, and draws bit sequence as '1' and '0'V 
 */
class VideoPulsePlot : DrawingArea {
    /**
     * @brief Constructs a new instance.
     *
     * Set parametrs at default values and connect signal
     */
    public this() @trusted { super();        
        reset(); addOnDraw(&onDraw);
    }

    /**
     * @brief Resets the object.
     *
     * Set parametrs at default values
     */
    public void reset() @safe {
        min_x_width = 30; max_x_width = 50;
        bit_sequence = ""; time_discrete = 0.01;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
    }

    /**
     * @brief  Request widget redraw.
     */
    public void drawRequest() @trusted {
        setSizeRequest(0, 0);
        queueDraw();
    }

    /**
     * @brief Called on draw.
     *
     * Slot to draw plot (make background, axes, text and plot line)
     *
     * @param _context  The cairo context for drawing
     * @param _widget   The drawing widget object
     *
     * @return true
     */
    protected bool onDraw(Scoped!Context _context, Widget _widget) {
        _widget.setSizeRequest(0, 0);

        GtkAllocation _w_alloc;
        _widget.getAllocation(_w_alloc);

        ulong actual_size = max_x_width;

        if(bit_sequence.length != 0) {
            actual_size = (_w_alloc.width - 65) / bit_sequence.length;

            if(actual_size > max_x_width) actual_size = max_x_width;
            else if(actual_size < min_x_width) actual_size = min_x_width;

            _widget.setSizeRequest(cast(int)(actual_size * bit_sequence.length + 65), _w_alloc.height);
        } _widget.getAllocation(_w_alloc);

        /// Drawing background color
        _context.setSourceRgba(background_color.r,
                               background_color.g,
                               background_color.b,
                               background_color.a);
        _context.paint();

        _context.setLineWidth(2);

        /// Drawing axes
        _context.setSourceRgba(axes_color.r,
                               axes_color.g,
                               axes_color.b,
                               axes_color.a);
        /// Drawing Y axis
        _context.moveTo(20, _w_alloc.height - 10); _context.lineTo(20, 10);
        _context.relLineTo(2, 5); _context.relLineTo(-2, -5);
        _context.relLineTo(-2, 5); _context.relLineTo(2, -5);
        _context.stroke();
        /// Drawing X axis
        _context.moveTo(10, _w_alloc.height - 20);
        _context.relLineTo(_w_alloc.width - 20, 0);
        _context.relLineTo(-5, 2); _context.relLineTo(5, -2);
        _context.relLineTo(-5, -2); _context.relLineTo(5, 2);
        _context.stroke();
        /// Drawin 1V value
        _context.moveTo(16, _w_alloc.height / 2);
        _context.relLineTo(8, 0); _context.stroke();
        ///Drawing X value
        _context.moveTo(20 + actual_size, _w_alloc.height - 16);
        _context.relLineTo(0, -8);
        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                _context.relMoveTo(actual_size, 8);
                _context.relLineTo(0, -8);
            }
        } _context.stroke();

        /// Making inscriptions
        cairo_text_extents_t extents;
        /// Plot name
        /*_context.setFontSize(12); _context.textExtents("График видеоимпульса", &extents);
        _context.moveTo(_w_alloc.width - 5 - extents.width, 12);
        _context.showText("График видеоимпульса");*/
        /// X axis name
        _context.setFontSize(10);
        _context.moveTo(_w_alloc.width - 35, _w_alloc.height - 5);
        _context.showText("t(сек.)");
        /// Y axis name
        _context.setFontSize(10);
        _context.moveTo(5, 10); _context.showText("А");
        _context.moveTo(3, 20); _context.showText("(В)");
        /// Y 1V value
        _context.moveTo(5, _w_alloc.height / 2 + 3);
        _context.showText("1");
        /// X values
        _context.textExtents(to!string(time_discrete), &extents);
        _context.moveTo(20 + actual_size - extents.width / 2, _w_alloc.height - 5);
        _context.showText(to!string(time_discrete));
        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                double act_dis = time_discrete * (i + 2);
                _context.textExtents(to!string(act_dis), &extents);
                _context.moveTo(20 + (actual_size * (i + 2)) - extents.width / 2, _w_alloc.height - 5);
                _context.showText(to!string(act_dis));
            }
        }

        /// Line drawing
        if(bit_sequence.length != 0) {
            _context.setSourceRgba(line_color.r,
                                   line_color.g,
                                   line_color.b,
                                   line_color.a);

            if(bit_sequence[0] == '1') _context.moveTo(20, _w_alloc.height / 2);
            else _context.moveTo(20, _w_alloc.height - 20);

            _context.relLineTo(actual_size, 0);

            for(size_t i = 1; i < bit_sequence.length; i++) {
                if(bit_sequence[i - 1] != bit_sequence[i]) {
                    _context.relLineTo(0, (_w_alloc.height / 2 - 20) * (bit_sequence[i] == '1' ? -1 : 1));                    
                }
                _context.relLineTo(actual_size, 0);
            }

            if(bit_sequence[bit_sequence.length - 1] == '1') {
                _context.relLineTo(0, (_w_alloc.height / 2 - 20));
            }

            _context.stroke();
        }

        return true;
    }

    private ubyte min_x_width;
    @property ubyte minXWidth() { return min_x_width; }
    @property ubyte minXWidth(ubyte min_x) { return min_x_width = min_x; }

    private ubyte max_x_width;
    @property ubyte maxXWidth() { return max_x_width; }
    @property ubyte maxXWidth(ubyte max_x) { return max_x_width = max_x; }

    private string bit_sequence; 
    @property string BitSequence() { return bit_sequence; }
    @property string BitSequence(string bits) { return bit_sequence = bits; }

    private double time_discrete;
    @property double TimeDiscrete() { return time_discrete; }
    @property double TimeDiscrete(double dis) { return time_discrete = dis; } 

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