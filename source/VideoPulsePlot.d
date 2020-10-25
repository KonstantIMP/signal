module VideoPulsePlot;

import cairo.c.types;
import gtk.c.types;

import gtk.DrawingArea;
import gtk.Widget;

import cairo.Context;

import std.conv;

struct rgba_color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}

class VideoPulsePlot : DrawingArea {
    public this() @trusted { super();
        
        reset(); addOnDraw(&onDraw);
    }

    public void reset() @safe {
        min_x_width = 30; max_x_width = 50;
        bit_sequence = ""; time_discrete = 0.03;
        line_color = rgba_color (0x00, 0xff, 0x00, 0xff);
        axes_color = rgba_color (0x00, 0x00, 0x00, 0xff);
        background_color = rgba_color (0xff, 0xff, 0xff, 0xff);
    }

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
        _context.setSourceRgba(cast(double)(background_color.r / 0xff),
                               cast(double)(background_color.g / 0xff),
                               cast(double)(background_color.b / 0xff),
                               cast(double)(background_color.a / 0xff));
        _context.paint();

        _context.setLineWidth(2);

        /// Drawing axes
        _context.setSourceRgba(cast(double)(axes_color.r / 0xff),
                               cast(double)(axes_color.g / 0xff),
                               cast(double)(axes_color.b / 0xff),
                               cast(double)(axes_color.a / 0xff));
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
        _context.setFontSize(12); _context.textExtents("График видеоимпульса", &extents);
        _context.moveTo(_w_alloc.width - 5 - extents.width, 12);
        _context.showText("График видеоимпульса");
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
            _context.setSourceRgba(cast(double)(line_color.r / 0xff),
                                   cast(double)(line_color.g / 0xff),
                                   cast(double)(line_color.b / 0xff),
                                   cast(double)(line_color.a / 0xff));

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

    public void drawRequest() @trusted {
        setSizeRequest(0, 0);
        queueDraw();
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

    private rgba_color line_color;
    @property rgba_color LineColor() { return line_color; }
    @property rgba_color LineColor(rgba_color line_c) { return line_color = line_c; }

    private rgba_color axes_color;
    @property rgba_color AxesColor() { return background_color; }
    @property rgba_color AxesColor(rgba_color axes_c) { return axes_color = axes_c; }

    private rgba_color background_color;
    @property rgba_color BackgroundColor() { return background_color; }
    @property rgba_color BackgroundColor(rgba_color back_c) { return background_color = back_c; }
}