/// @file   VideoPulsePlot.d
/// 
/// @brief  VideoPulsePlot class description
///
/// @author KonstantIMP
/// @date   2020
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

import Color;

/// @brief  VideoPulsePlot  Class for drawing video pulse plot
///
/// Plot for viewing bit sequence logic voltage level extenting by time
/// It is a composite widget
///
/// GtkOverlay                  # Base Widget
/// |__ Child
/// |   |__ GtkScrolledWindow   # For plot scaling
/// |       |__ GtkDrawingArea  # For plot drawing
/// |__ Overlay
///     |__ GtkLabel            # For plot name drawing
class VideoPulsePlot : Overlay {
    /// @brief plot_name    Label for plot name drawing
    private Label plot_name;
    /// @brief plot_area    DrawingArea for plot drawing(Axes and line)
    private DrawingArea plot_area;
    /// @brief plot_sw      ScrolledWindow for plot scaling
    private ScrolledWindow plot_sw;

    /// @brief  Basic constructor for widget
    /// Init child widgets, build ui and connect signals
    public this() @trusted { super();
        plot_name = new Label("");
        plot_area = new DrawingArea();
        plot_sw = new ScrolledWindow();

        createUI(); resetPlot();
        plot_area.addOnDraw(&onDraw);
    }

    /// @brief resetPlot    Set plot attributes at default values
    public void resetPlot() @trusted {
        min_x_width = 30; max_x_width = 50;
        bit_sequence = ""; time_discrete = 0.01;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
        plot_name.setMarkup("<span size='small' foreground='#000000ff' background='#ffffffff'>График видеоимпульса</span>");
    }

    /// @brief drawRequest  Request plot area redraw at GTK
    public void drawRequest() @trusted {
        /// Set plot area size as zeroes for smart plot scale
        plot_area.setSizeRequest(0, 0);
        plot_area.queueDraw();
    }

    /// @brief createUI Setting correct ui struct
    private void createUI() @trusted {
        /// Adding plot_sw to Overlay(child)
        add(cast(Widget)(plot_sw));
        /// Adding plot_area to ScrolledWindow(child)
        plot_sw.add(cast(Widget)(plot_area)); 
        
        /// Plot name uses markup for work with text and background colors
        plot_name.setUseMarkup(true);
        plot_name.setMarkup("<span size='small' foreground='#000000' background='#ffffff'>График видеоимпульса</span>");

        /// Setting plot_name as OverlayWidget
        addOverlay(cast(Widget)(plot_name));
        /// Setting plot_name position
        plot_name.setProperty("margin", 5);
        plot_name.setProperty("halign", GtkAlign.END);
        plot_name.setProperty("valign", GtkAlign.START); 
    }

    /// @brief onDraw   Plot drawing slot
    /// This slot is called every time plot redraw
    ///
    /// @param[in]  _context    Cairo context for actually draw
    /// @param[in]  _widget     Widget that contains cairo surface for drawing
    ///
    /// @return     bool        True if drawing was succesfull
    protected bool onDraw(Scoped!Context _context, Widget _widget) @trusted {
        /// _w_alloc is struct with _widget size
        /// _actial_size is distance between unit lines
        GtkAllocation _w_alloc; ulong _actual_size;

        sizeAllocate(_widget, _w_alloc, _actual_size);

        drawBackground(_context);
        drawAxes(_context, _w_alloc);
        
        makeAxesMarkup(_context, _w_alloc, _actual_size);
        makeInscriptions(_context, _w_alloc, _actual_size);
        
        if(bit_sequence.length != 0) drawPlotLine(_context, _w_alloc, _actual_size);

        return true;
    }

    /// @brief sizeAllocate A function that calculates the size of the plot
    ///                             based on the number of bits in the sequence
    ///
    /// @param[in]  w           Widget to be resized
    /// @param[out] w_alloc     Calculated widget size
    /// @param[out] actual_size Calculated distance between unit lines
    protected void sizeAllocate(ref Widget w, out GtkAllocation w_alloc, out ulong actual_size) @trusted {
        w.setSizeRequest(0, 0); w.getAllocation(w_alloc); actual_size = max_x_width;

        if(bit_sequence.length != 0) {
            actual_size = (w_alloc.width - 65) / bit_sequence.length;

            if(actual_size > max_x_width) actual_size = max_x_width;
            else if(actual_size < min_x_width) actual_size = min_x_width;

            w.setSizeRequest(cast(int)(actual_size * bit_sequence.length + 65), w_alloc.height);
        } w.getAllocation(w_alloc);
    }

    /// @brief drawBackground   Draw plot background
    ///
    /// @param[in] cairo_context    Cairo context for drawing
    protected void drawBackground(ref Scoped!Context cairo_context) @trusted {
        cairo_context.setSourceRgba(background_color.r,
                                    background_color.g,
                                    background_color.b,
                                    background_color.a);
        cairo_context.paint();
    }

    /// @brief drawAxes Draw plot axes
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void drawAxes(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.setLineWidth(2);
        cairo_context.setSourceRgba(axes_color.r,
                                    axes_color.g,
                                    axes_color.b,
                                    axes_color.a);

        drawXAxis(cairo_context, w_alloc);
        drawYAxis(cairo_context, w_alloc);
    }

    /// @brief drawXAxis Draw X plot axis
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void drawXAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(10, w_alloc.height - 20);
        cairo_context.relLineTo(w_alloc.width - 20, 0);
        cairo_context.relLineTo(-5, 2);  cairo_context.relLineTo(5, -2);
        cairo_context.relLineTo(-5, -2); cairo_context.relLineTo(5, 2);
        cairo_context.stroke();
    }

    /// @brief drawYAxis Draw Y plot axis
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void drawYAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(20, w_alloc.height - 10); cairo_context.lineTo(20, 10);
        cairo_context.relLineTo(2, 5);  cairo_context.relLineTo(-2, -5);
        cairo_context.relLineTo(-2, 5); cairo_context.relLineTo(2, -5);
        cairo_context.stroke();
    }

    /// @brief makeAxesMarkup Draw plot axes markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void makeAxesMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        makeXAxisMarkup(cairo_context, w_alloc, actual_size);
        makeYAxisMarkup(cairo_context, w_alloc);
    }

    /// @brief makeXAxisMarkup Draw X plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void makeXAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.moveTo(20 + actual_size, w_alloc.height - 16);
        cairo_context.relLineTo(0, -8);
        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                cairo_context.relMoveTo(actual_size, 8);
                cairo_context.relLineTo(0, -8);
            }
        } cairo_context.stroke();
    }

    /// @brief makeYAxisMarkup Draw Y plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void makeYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(16, w_alloc.height / 2);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
    }

    /// @brief makeInscriptions Draw plot inscriprion
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void makeInscriptions(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        textYAxisName(cairo_context, w_alloc);
        textYAxisMarkup(cairo_context, w_alloc);
        textXAxisName(cairo_context, w_alloc, actual_size);
        textXAxisMarkup(cairo_context, w_alloc, actual_size);
    }

    /// @brief textYAxisName Draw Y plot axis name
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void textYAxisName(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(5, 10); cairo_context.showText("А");
        cairo_context.moveTo(3, 20); cairo_context.showText("(В)");
    }

    /// @brief makeYAxisMarkup Draw Y plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void textYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(5, w_alloc.height / 2 + 3);
        cairo_context.showText("1");
    }

    /// @brief textXAxisName Draw X plot axis name
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void textXAxisName(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(w_alloc.width - 35, w_alloc.height - 5);
        cairo_context.showText("t(сек.)");
    }

    /// @brief makeXAxisMarkup Draw X plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void textXAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_text_extents_t text_extent;

        cairo_context.textExtents(to!string(time_discrete), &text_extent);
        cairo_context.moveTo(20 + actual_size - text_extent.width / 2, w_alloc.height - 5);
        cairo_context.showText(to!string(time_discrete));

        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                double act_dis = time_discrete * (i + 2);
                cairo_context.textExtents(to!string(act_dis), &text_extent);
                cairo_context.moveTo(20 + (actual_size * (i + 2)) - text_extent.width / 2, w_alloc.height - 5);
                cairo_context.showText(to!string(act_dis));
            }
        }
    }

    /// @brief drawPlotLine Draw plot line
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void drawPlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setSourceRgba(line_color.r,
                                    line_color.g,
                                    line_color.b,
                                    line_color.a);

        if(bit_sequence[0] == '1') cairo_context.moveTo(20, w_alloc.height / 2);
        else cairo_context.moveTo(20, w_alloc.height - 20);

        uint delta_height = w_alloc.height / 2 - 20;
        cairo_context.relLineTo(actual_size, 0);

        for(size_t i = 1; i < bit_sequence.length; i++) {
            if(bit_sequence[i - 1] != bit_sequence[i]) {
                cairo_context.relLineTo(0, (bit_sequence[i] == '1' ? -delta_height : delta_height));                    
            }
            cairo_context.relLineTo(actual_size, 0);
        }

        if(bit_sequence[bit_sequence.length - 1] == '1') {
            cairo_context.relLineTo(0, delta_height);
        }

        cairo_context.stroke();
    }

    /// @brief Minimum distance between unit lines
    private ubyte min_x_width;
    /// @brief minXWidth    Getter for min_x_width
    @property ubyte minXWidth() @trusted @nogc { return min_x_width; }
    /// @brief minXWidth    Setter for min_x_width
    @property ubyte minXWidth(ubyte min_x) @trusted @nogc { return min_x_width = min_x; }

    /// @brief Maximum distance between unit lines
    private ubyte max_x_width;
    /// @brief maxXWidth    Getter for max_x_width
    @property ubyte maxXWidth() @trusted @nogc { return max_x_width; }
    /// @brief maxXWidth    Setter for max_x_width
    @property ubyte maxXWidth(ubyte max_x) @trusted @nogc { return max_x_width = max_x; }

    /// @brief Bit sequence for displaing
    private string bit_sequence; 
    /// @brief bitSequence    Getter for bit_sequence
    @property string bitSequence() @trusted @nogc { return bit_sequence; }
    /// @brief bitSequence    Setter for bit_sequence
    @property string bitSequence(string bits) @trusted { return bit_sequence = bits; }

    /// @brief Time discrete for X axis
    private double time_discrete;
    /// @brief timeDiscrete    Getter for time_discrete
    @property double timeDiscrete() @trusted @nogc { return time_discrete; }
    /// @brief timeDiscrete    Setter for time_discrete
    @property double timeDiscrete(double dis) @trusted @nogc { return time_discrete = dis; } 

    /// @brief Plot line color
    private RgbaColor line_color;
    /// @brief lineColor    Getter for line_color
    @property RgbaColor lineColor() @trusted @nogc { return line_color; }
    /// @brief lineColor    Setter for line_color
    @property RgbaColor lineColor(RgbaColor line_c) @trusted @nogc { return line_color = line_c; }

    /// @brief Plot axes color
    private RgbaColor axes_color;
    /// @brief axesColor    Getter for axes_color
    @property RgbaColor axesColor() @trusted @nogc { return background_color; }
    /// @brief axesColor    Setter for axes_color
    @property RgbaColor axesColor(RgbaColor axes_c) @trusted {
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

    /// @brief Plot background color
    private RgbaColor background_color;
    /// @brief backgroundColor    Getter for background_color
    @property RgbaColor backgroundColor() @trusted @nogc { return background_color; }
    /// @brief backgroundColor    Setter for background_color
    @property RgbaColor backgroundColor(RgbaColor back_c) @trusted {
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