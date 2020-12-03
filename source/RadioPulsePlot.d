/// @file   RadioPulsePlot.d
/// 
/// @brief  RadioPulsePlot class description
///
/// @license LGPLv3 (see LICENSE file)
/// @author KonstantIMP
/// @date   2020
module RadioPulsePlot;

import cairo.c.types;
import gtk.c.types;

import gtk.ScrolledWindow;
import gtk.DrawingArea;
import gtk.Overlay;
import gtk.Widget;
import gtk.Label;

import cairo.Context;

import std.conv;
import std.math;
import std.string;
import std.conv;

import Color;

/// @brief Enumeration of supported modulation modes for plot drawing
enum ModeType {
    frecuency_mode, ///> Frequency modulation mode
    amplitude_mode, ///> Aplitude modulation mode
    phase_mode      ///> Phase modulation mode
}

/// @brief  RadioPulsePlot  Class for drawing radio pulse plot
///
/// Plot for viewing bit sequence at radio channel
/// It is a composite widget
///
/// GtkOverlay                  # Base widget
/// |__ Child
/// |   |__ GtkScrolledWindow   # For plot scaling
/// |       |__ GtkDrawingArea  # For plot drawing
/// |__ Overlay
///     |__ GtkLabel            # For plot name drawing
class RadioPulsePlot : Overlay {
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

        createUI();
        resetPlot(); plot_area.addOnDraw(&onDraw);
    }

    /// @brief resetPlot    Set plot attributes at default values
    public void resetPlot() @safe {
        f_width = 20; mod_type = ModeType.phase_mode; 
        bit_sequence = ""; freq = 100; time_discrete = 0.2;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
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
        plot_name.setMarkup("<span size='small' foreground='#000000' background='#ffffff'>График радиосигнала</span>");

        /// Setting plot_name as OverlayWidget
        addOverlay(cast(Widget)plot_name);

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
        GtkAllocation _w_alloc; ulong _actual_size;

        sizeAllocate(_widget, _w_alloc, _actual_size);

        drawBackground(_context);
        drawAxes(_context, _w_alloc);
        
        makeAxesMarkup(_context, _w_alloc, _actual_size);
        makeInscriptions(_context, _w_alloc, _actual_size);

        if(bit_sequence.length != 0) {
            drawPlotLine(_context, _w_alloc, _actual_size);
        }

        return true;
    }

    /// @brief sizeAllocate A function that calculates the size of the plot
    ///                             based on the number of bits in the sequence
    ///
    /// @param[in]  w           Widget to be resized
    /// @param[out] w_alloc     Calculated widget size
    /// @param[out] actual_size Calculated distance between unit lines
    protected void sizeAllocate(ref Widget w, out GtkAllocation w_alloc, out ulong actual_size) @trusted {
        w.setSizeRequest(0, 0);
        
        w.getAllocation(w_alloc); actual_size = f_width;

        if(bit_sequence.length != 0) {
            actual_size = cast(ulong)(f_width * cast(double)(time_discrete * freq));
            if(actual_size < f_width) actual_size = f_width;

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
        cairo_context.moveTo(10, w_alloc.height / 2);
        cairo_context.relLineTo(w_alloc.width - 20, 0);
        cairo_context.relLineTo(-5, 2);     cairo_context.relLineTo(5, -2);
        cairo_context.relLineTo(-5, -2);    cairo_context.relLineTo(5, 2);
        cairo_context.stroke();
    }

    /// @brief drawYAxis Draw Y plot axis
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void drawYAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(20, w_alloc.height - 10);     cairo_context.lineTo(20, 10);
        cairo_context.relLineTo(2, 5);      cairo_context.relLineTo(-2, -5);
        cairo_context.relLineTo(-2, 5);     cairo_context.relLineTo(2, -5);
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
        cairo_context.moveTo(20 + actual_size, w_alloc.height / 2 - 4);
        cairo_context.relLineTo(0, 8);
        if(bit_sequence.length != 0) {
            for(int i = 0; i < bit_sequence.length - 1; i++) {
                cairo_context.relMoveTo(actual_size, -8);
                cairo_context.relLineTo(0, 8);
            }
        }  cairo_context.stroke();
    }

    /// @brief makeYAxisMarkup Draw Y plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void makeYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        /// Drawing +1V value
        cairo_context.moveTo(16, w_alloc.height / 6);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
        /// Drawing -1V value
        cairo_context.moveTo(16, w_alloc.height / 6 * 5);
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
        cairo_context.moveTo(5, 10); 
        cairo_context.showText("А");
    }

    /// @brief makeYAxisMarkup Draw Y plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    protected void textYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        /// Y 1V value
        cairo_context.moveTo(5, w_alloc.height / 6 + 3);
        cairo_context.showText("1");
        /// Y -1V value
        cairo_context.moveTo(5, w_alloc.height / 6 * 5 + 3);
        cairo_context.showText("-1");
    }

    /// @brief textXAxisName Draw X plot axis name
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void textXAxisName(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(w_alloc.width - 35, w_alloc.height / 2 + 12);
        cairo_context.showText("t(сек.)");
    }

    /// @brief makeXAxisMarkup Draw X plot axis markup
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void textXAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.rotate(3.1415 / 2);
        
        int reveresed_width = -cast(int)(actual_size);
        int reveresed_height = w_alloc.height / 2 + 6;

        cairo_context.moveTo(reveresed_height, reveresed_width - 16);
        cairo_context.showText(to!string(time_discrete));

        double current_discrete = time_discrete * 2;

        for(int i = 1; i < bit_sequence.length; i++) {
            cairo_context.moveTo(reveresed_height, reveresed_width * (i + 1) - 16);
            cairo_context.showText(to!string(current_discrete));
            current_discrete = current_discrete + time_discrete;
        }

        cairo_context.rotate(-(3.1415 / 2));
    }

    /// @brief drawPlotLine Draw plot line
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void drawPlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setLineWidth(1);
        cairo_context.moveTo(20, w_alloc.height / 2);
        cairo_context.setSourceRgba(line_color.r,
                                    line_color.g,
                                    line_color.b,
                                    line_color.a);
        
        final switch(mod_type) {
            case ModeType.phase_mode : drawPhasePlotLine(cairo_context, w_alloc, actual_size); break;
            case ModeType.amplitude_mode : drawAmplitudePlotLine(cairo_context, w_alloc, actual_size); break;
            case ModeType.frecuency_mode : drawFrequencyPlotLine(cairo_context, w_alloc, actual_size); break;
        }
    }

    /// @brief drawPhasePlotLine Draw plot line for phase modulation mode
    /// Phase changes every time signal changes
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void drawPhasePlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * freq));

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }
        
        double line_height = cast(double)(w_alloc.height / 3);
        line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(actual_size) / cast(double)(need_draw) / 4;
        double cur_x, cur_y;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

            for(int j = 0; j < need_draw * 2; j++) {
                cairo_context.relLineTo(0, (last_state == true ? -line_height : line_height));

                cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + del_x_arc, cur_y, del_x_arc, 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + del_x_arc, cur_y, del_x_arc, 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, (last_state == true ? line_height : -line_height));
                last_state = !last_state;
            }
        
            cairo_context.stroke();
            cairo_context.moveTo(20 + actual_size * (i + 1), w_alloc.height / 2);
        }
    }

    /// @brief drawAplitudePlotLine Draw plot line for amplitude modulation mode
    /// Amplitude becames less Bit is in zero value
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void drawAmplitudePlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * freq));

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double del_x_arc = cast(double)(actual_size) / cast(double)(need_draw) / 4;
        double cur_x, cur_y;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            double line_height;

            if(bit_sequence[i] == '1') line_height = cast(double)(w_alloc.height / 3);
            else line_height = cast(double)(w_alloc.height / 6);

            line_height = line_height - del_x_arc; 

            for(int j = 0; j < need_draw * 2; j++) {
                cairo_context.relLineTo(0, line_height * (last_state == true ? -1 : 1));

                cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + del_x_arc, cur_y, del_x_arc, 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + del_x_arc, cur_y, del_x_arc, 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, line_height * (last_state == true ? 1 : -1));
                last_state = !last_state;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + actual_size * (i + 1), w_alloc.height / 2);
        }
    }

    /// @brief drawFrequencyPlotLine Draw plot line for frequency modulation mode
    /// Frequency becomes less every time Bit is in zero value
    ///
    /// @param[in] cairo_context   Cairo context for drawing
    /// @param[in] w_alloc          Plot area size
    /// @param[in] actual_size      Distance between unit lines
    protected void drawFrequencyPlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * freq));

        if(need_draw < 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(w_alloc.height / 3);
        line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4;

        double del_x_cur = cast(double)(actual_size) / cast(double)(need_draw);
        double cur_x, cur_y; 

        for(int i = 0; i < bit_sequence.length; i++) {
            for(int j = 0; j < need_draw * (bit_sequence[i] == '1' ? 2 : 1); j++) {
                cairo_context.relLineTo(0, (last_state == true ? -line_height : line_height));

                cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + del_x_cur / (bit_sequence[i] == '1' ? 4 : 2), cur_y, del_x_cur / (bit_sequence[i] == '1' ? 4 : 2), 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + del_x_cur / (bit_sequence[i] == '1' ? 4 : 2), cur_y, del_x_cur / (bit_sequence[i] == '1' ? 4 : 2), 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, (last_state == true ? line_height : -line_height));
                last_state = !last_state;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + actual_size * (i + 1), w_alloc.height / 2);
        }
    }

    /// @brief  Distance between units
    private ubyte f_width;
    /// @brief  fWidth  Getter for f_width
    @property ubyte fWidth() { return f_width; }
    /// @brief  fWidth  Setter for f_width
    @property ubyte fWidth(ubyte f) { return f_width = f; }

    /// @brief Bit sequence for displaing
    private string bit_sequence; 
    /// @brief bitSequence    Getter for bit_sequence
    @property string bitSequence() { return bit_sequence; }
    /// @brief bitSequence    Setter for bit_sequence
    @property string bitSequence(string bits) { return bit_sequence = bits; }

    /// @brief Frequency for considering plot
    private ulong freq;
    /// @brief  frequency   Getter for freq
    @property ulong frequency() { return freq; }
    /// @brief  frequency   Setter for freq
    @property ulong frequency(ulong fr) { return freq = fr; } 

    /// @brief Time discrete for X axis
    private double time_discrete;
    /// @brief timeDiscrete    Getter for time_discrete
    @property double timeDiscrete() { return time_discrete; }
    /// @brief timeDiscrete    Setter for time_discrete
    @property double timeDiscrete(double dis) { return time_discrete = dis; } 

    /// @brief  Modulation type for plot drawing
    private ModeType mod_type;
    /// @brief  modeType    Getter for mod_type
    @property ModeType modeType() { return mod_type; }
    /// @brief  modeType    Setter for mod_type
    @property ModeType modeType(ModeType mt) { return mod_type = mt; }

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