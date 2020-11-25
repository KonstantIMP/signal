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

import gtk.ScrolledWindow;
import gtk.DrawingArea;
import gtk.Overlay;
import gtk.Widget;
import gtk.Label;

import cairo.Context;

import std.conv;
import std.math;

import Color;

enum modType {
    frecuency_mode,
    amplitude_mode,
    phase_mode
}

class RadioPulsePlot : Overlay {
    private Label plot_name;
    private DrawingArea plot_area;
    private ScrolledWindow plot_sw;

    public this() @trusted { super();  
        plot_name = new Label("");
        plot_area = new DrawingArea();
        plot_sw = new ScrolledWindow();

        createUI();
        resetPlot(); plot_area.addOnDraw(&onDraw);
    }

    public void resetPlot() @safe {
        f_width = 20; mod_type = modType.phase_mode; 
        bit_sequence = ""; frequency = 100; time_discrete = 0.2;
        line_color = RgbaColor (0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor (0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor (1.0, 1.0, 1.0, 1.0);
    }

    public void drawRequest() @trusted {
        plot_area.setSizeRequest(0, 0);
        plot_area.queueDraw();
    }

    private void createUI() @trusted {
        add(cast(Widget)(plot_sw));

        plot_sw.add(cast(Widget)(plot_area));

        plot_name.setUseMarkup(true);
        plot_name.setMarkup("<span size='small' foreground='#000000' background='#ffffff'>График радиосигнала</span>");

        addOverlay(cast(Widget)plot_name);

        plot_name.setProperty("margin", 5);
        plot_name.setProperty("halign", GtkAlign.END);
        plot_name.setProperty("valign", GtkAlign.START); 
    }

    protected bool onDraw(Scoped!Context _context, Widget _widget) {
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

    protected void sizeAllocate(ref Widget w, out GtkAllocation w_alloc, out ulong actual_size) @trusted {
        w.setSizeRequest(0, 0);
        
        w.getAllocation(w_alloc); actual_size = f_width;

        if(bit_sequence.length != 0) {
            actual_size = cast(ulong)(f_width * cast(double)(time_discrete * frequency));
            if(actual_size < f_width) actual_size = f_width;

            w.setSizeRequest(cast(int)(actual_size * bit_sequence.length + 65), w_alloc.height);
        } w.getAllocation(w_alloc);   
    }

    protected void drawBackground(ref Scoped!Context cairo_context) @trusted {
        cairo_context.setSourceRgba(background_color.r,
                                    background_color.g,
                                    background_color.b,
                                    background_color.a);
        cairo_context.paint();
    }

    protected void drawAxes(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.setLineWidth(2);
        cairo_context.setSourceRgba(axes_color.r,
                                    axes_color.g,
                                    axes_color.b,
                                    axes_color.a);

        drawXAxis(cairo_context, w_alloc);
        drawYAxis(cairo_context, w_alloc);
    }

    protected void drawXAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(10, w_alloc.height / 2);
        cairo_context.relLineTo(w_alloc.width - 20, 0);
        cairo_context.relLineTo(-5, 2);     cairo_context.relLineTo(5, -2);
        cairo_context.relLineTo(-5, -2);    cairo_context.relLineTo(5, 2);
        cairo_context.stroke();
    }

    protected void drawYAxis(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.moveTo(20, w_alloc.height - 10);     cairo_context.lineTo(20, 10);
        cairo_context.relLineTo(2, 5);      cairo_context.relLineTo(-2, -5);
        cairo_context.relLineTo(-2, 5);     cairo_context.relLineTo(2, -5);
        cairo_context.stroke();
    }

    protected void makeAxesMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        makeXAxisMarkup(cairo_context, w_alloc, actual_size);
        makeYAxisMarkup(cairo_context, w_alloc);
    }

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

    protected void makeYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        /// Drawing +1V value
        cairo_context.moveTo(16, w_alloc.height / 6);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
        /// Drawing -1V value
        cairo_context.moveTo(16, w_alloc.height / 6 * 5);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
    }

    protected void makeInscriptions(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        textYAxisName(cairo_context, w_alloc);
        textYAxisMarkup(cairo_context, w_alloc);
        textXAxisName(cairo_context, w_alloc, actual_size);
        textXAxisMarkup(cairo_context, w_alloc, actual_size);
    }

    protected void textYAxisName(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(5, 10); 
        cairo_context.showText("А");
    }

    protected void textYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation w_alloc) @trusted {
        /// Y 1V value
        cairo_context.moveTo(5, w_alloc.height / 6 + 3);
        cairo_context.showText("1");
        /// Y -1V value
        cairo_context.moveTo(5, w_alloc.height / 6 * 5 + 3);
        cairo_context.showText("-1");
    }

    protected void textXAxisName(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(w_alloc.width - 35, w_alloc.height / 2 + 12);
        cairo_context.showText("t(сек.)");
    }

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

    protected void drawPlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        cairo_context.setLineWidth(1);
        cairo_context.moveTo(20, w_alloc.height / 2);
        cairo_context.setSourceRgba(line_color.r,
                                    line_color.g,
                                    line_color.b,
                                    line_color.a);
        
        final switch(mod_type) {
            case ModType.phase_mode : drawPhasePlotLine(cairo_context, w_alloc, actual_size); break;
            case ModType.amplitude_mode : drawAmplitudePlotLine(cairo_context, w_alloc, actual_size); break;
            case ModType.frecuency_mode : drawFrequencyPlotLine(cairo_context, w_alloc, actual_size); break;
        }

        //cairo_context.stroke();
    }

    protected void drawPhasePlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * frequency));

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }
        
        double line_height = cast(double)(w_alloc.height / 3);
        line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(actual_size) / cast(double)(need_draw) / 4;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

            for(int j = 0; j < need_draw * 2; j++) {
                cairo_context.relLineTo(0, (last_state == true ? -line_height : line_height));

                double cur_x, cur_y; cairo_context.getCurrentPoint(cur_x, cur_y);
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

    protected void drawAmplitudePlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * frequency));

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        for(size_t i = 0; i < bit_sequence.length; i++) {
            double line_height;

            if(bit_sequence[i] == '1') line_height = cast(double)(w_alloc.height / 3);
            else line_height = cast(double)(w_alloc.height / 6);

            line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4; 

            for(int j = 0; j < need_draw * 2; j++) {
                cairo_context.relLineTo(0, line_height * (last_state == true ? -1 : 1));

                double cur_x, cur_y; cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / 4, cur_y, cast(double)(actual_size) / cast(double)(need_draw) / 4, 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, line_height * (last_state == true ? 1 : -1));
                last_state = !last_state;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + actual_size * (i + 1), w_alloc.height / 2);
        }
    }

    protected void drawFrequencyPlotLine(ref Scoped!Context cairo_context, GtkAllocation w_alloc, ulong actual_size) @trusted {
        bool last_state = true; uint need_draw;
        need_draw = cast(uint)(round(time_discrete * frequency));

        if(need_draw < 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(w_alloc.height / 3);
        line_height = line_height - cast(double)(actual_size) / cast(double)(need_draw) / 4;

        for(int i = 0; i < bit_sequence.length; i++) {
            for(int j = 0; j < need_draw * (bit_sequence[i] == '1' ? 2 : 1); j++) {
                cairo_context.relLineTo(0, line_height * (last_state == true ? -1 : 1));

                double cur_x, cur_y; cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / (bit_sequence[i] == '1' ? 4 : 2), cur_y, (cast(double)(actual_size) / cast(double)(need_draw) / (bit_sequence[i] == '1' ? 4 : 2)), 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + cast(double)(actual_size) / cast(double)(need_draw) / (bit_sequence[i] == '1' ? 4 : 2), cur_y, (cast(double)(actual_size) / cast(double)(need_draw) / (bit_sequence[i] == '1' ? 4 : 2)), 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, line_height * (last_state == true ? 1 : -1));
                last_state = !last_state;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + actual_size * (i + 1), w_alloc.height / 2);
        }
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