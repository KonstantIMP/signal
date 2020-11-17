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

import gtk.ScrolledWindow;
import gtk.DrawingArea;
import gtk.Overlay;
import gtk.Widget;
import gtk.Label;

import cairo.Context;

import std.string;
import std.stdio;
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
class VideoPulsePlot : Overlay {
    private Label plot_name;
    private DrawingArea plot_area;
    private ScrolledWindow plot_sw;

    public this() @trusted { super();
        plot_name = new Label("");
        plot_area = new DrawingArea();
        plot_sw = new ScrolledWindow();

        createUI(); resetPlot();
        plot_area.addOnDraw(&onDraw);
    }

    public void resetPlot() @trusted {
        min_x_width = 30; max_x_width = 50;
        bit_sequence = ""; time_discrete = 0.01;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
        plot_name.setMarkup("<span size='small' foreground='#000000ff' background='#ffffffff'>График видеоимпульса</span>");
    }

    public void drawRequest() @trusted {
        plot_area.setSizeRequest(0, 0);
        plot_area.queueDraw();
    }

    private void createUI() @trusted {
        add(cast(Widget)(plot_sw));
        plot_sw.add(cast(Widget)(plot_area)); 
        
        plot_name.setUseMarkup(true);
        plot_name.setMarkup("<span size='small' foreground='#000000' background='#ffffff'>График видеоимпульса</span>");

        addOverlay(cast(Widget)(plot_name));
        plot_name.setProperty("margin", 5);
        plot_name.setProperty("halign", GtkAlign.END);
        plot_name.setProperty("valign", GtkAlign.START); 
    }

    protected bool onDraw(Scoped!Context _context, Widget _widget) {
        GtkAllocation _w_alloc; ulong _actual_size;

        sizeAllocate(_widget, _w_alloc, _actual_size);

        drawBackground(_context);
        drawAxes(_context, _w_alloc);
        
        /// Drawin 1V value
        _context.moveTo(16, _w_alloc.height / 2);
        _context.relLineTo(8, 0); _context.stroke();
        ///Drawing X value
        _context.moveTo(20 + _actual_size, _w_alloc.height - 16);
        _context.relLineTo(0, -8);
        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                _context.relMoveTo(_actual_size, 8);
                _context.relLineTo(0, -8);
            }
        } _context.stroke();

        /// Making inscriptions
        cairo_text_extents_t extents;
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
        _context.moveTo(20 + _actual_size - extents.width / 2, _w_alloc.height - 5);
        _context.showText(to!string(time_discrete));
        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                double act_dis = time_discrete * (i + 2);
                _context.textExtents(to!string(act_dis), &extents);
                _context.moveTo(20 + (_actual_size * (i + 2)) - extents.width / 2, _w_alloc.height - 5);
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

            _context.relLineTo(_actual_size, 0);

            for(size_t i = 1; i < bit_sequence.length; i++) {
                if(bit_sequence[i - 1] != bit_sequence[i]) {
                    _context.relLineTo(0, (_w_alloc.height / 2 - 20) * (bit_sequence[i] == '1' ? -1 : 1));                    
                }
                _context.relLineTo(_actual_size, 0);
            }

            if(bit_sequence[bit_sequence.length - 1] == '1') {
                _context.relLineTo(0, (_w_alloc.height / 2 - 20));
            }

            _context.stroke();
        }

        return true;
    }

    protected void sizeAllocate(ref Widget w, out GtkAllocation w_alloc, out ulong actual_size) @trusted {
        w.setSizeRequest(0, 0); w.getAllocation(w_alloc); actual_size = max_x_width;

        if(bit_sequence.length != 0) {
            actual_size = (w_alloc.width - 65) / bit_sequence.length;

            if(actual_size > max_x_width) actual_size = max_x_width;
            else if(actual_size < min_x_width) actual_size = min_x_width;

            w.setSizeRequest(cast(int)(actual_size * bit_sequence.length + 65), w_alloc.height);
        } w.getAllocation(w_alloc);
    }

    protected void drawBackground(ref Scoped!Context cairo_context) {
        cairo_context.setSourceRgba(background_color.r,
                                    background_color.g,
                                    background_color.b,
                                    background_color.a);
        cairo_context.paint();
    }

    private void drawAxes(ref Scoped!Context cairo_context, GtkAllocation w_alloc) {
        cairo_context.setLineWidth(2);
        cairo_context.setSourceRgba(axes_color.r,
                                    axes_color.g,
                                    axes_color.b,
                                    axes_color.a);

        drawXAxis(cairo_context, w_alloc);
        drawYAxis(cairo_context, w_alloc);
    }

    private void drawXAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) {
        cairo_context.moveTo(10, w_alloc.height - 20);
        cairo_context.relLineTo(w_alloc.width - 20, 0);
        cairo_context.relLineTo(-5, 2);  cairo_context.relLineTo(5, -2);
        cairo_context.relLineTo(-5, -2); cairo_context.relLineTo(5, 2);
        cairo_context.stroke();
    }

    private void drawYAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) {
        cairo_context.moveTo(20, w_alloc.height - 10); cairo_context.lineTo(20, 10);
        cairo_context.relLineTo(2, 5);  cairo_context.relLineTo(-2, -5);
        cairo_context.relLineTo(-2, 5); cairo_context.relLineTo(2, -5);
        cairo_context.stroke();
    }

    private ubyte min_x_width;
    @property ubyte minXWidth() { return min_x_width; }
    @property ubyte minXWidth(ubyte min_x) { return min_x_width = min_x; }

    private ubyte max_x_width;
    @property ubyte maxXWidth() { return max_x_width; }
    @property ubyte maxXWidth(ubyte max_x) { return max_x_width = max_x; }

    private string bit_sequence; 
    @property string bitSequence() { return bit_sequence; }
    @property string bitSequence(string bits) { return bit_sequence = bits; }

    private double time_discrete;
    @property double timeDiscrete() { return time_discrete; }
    @property double timeDiscrete(double dis) { return time_discrete = dis; } 

    private RgbaColor line_color;
    @property RgbaColor lineColor() { return line_color; }
    @property RgbaColor lineColor(RgbaColor line_c) { return line_color = line_c; }

    private RgbaColor axes_color;
    @property RgbaColor axesColor() { return background_color; }
    @property RgbaColor axesColor(RgbaColor axes_c) {
        string f_color = rightJustify(to!string(toChars!16(cast(uint)(axes_c.r * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_c.g * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_c.b * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_c.a * 255))), 2, '0');
        string b_color = rightJustify(to!string(toChars!16(cast(uint)(background_color.r * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(background_color.g * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(background_color.b * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(background_color.a * 255))), 2, '0');

        plot_name.setMarkup("<span size='small' foreground='#" ~ f_color ~ "' background='#" ~ b_color ~ "'>График видеоимпульса</span>");

        return axes_color = axes_c;    
    }

    private RgbaColor background_color;
    @property RgbaColor backgroundColor() { return background_color; }
    @property RgbaColor backgroundColor(RgbaColor back_c) {
        string b_color = rightJustify(to!string(toChars!16(cast(uint)(back_c.r * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(back_c.g * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(back_c.b * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(back_c.a * 255))), 2, '0');
        string f_color = rightJustify(to!string(toChars!16(cast(uint)(axes_color.r * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_color.g * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_color.b * 255))), 2, '0') ~
                         rightJustify(to!string(toChars!16(cast(uint)(axes_color.a * 255))), 2, '0');

        plot_name.setMarkup("<span size='small' foreground='#" ~ f_color ~ "' background='#" ~ b_color ~ "'>График видеоимпульса</span>");

        return background_color = back_c;
    }
}