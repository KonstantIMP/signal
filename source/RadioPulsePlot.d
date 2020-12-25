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

import PlotViewer;
import Color;

/// @brief Enumeration of supported modulation modes for plot drawing
enum ModeType {
    frecuency_mode, ///> Frequency modulation mode
    amplitude_mode, ///> Aplitude modulation mode
    phase_mode      ///> Phase modulation mode
}

class RadioPulsePlot : PlotViewer {
    public this() { super("График радиосигнала");
        f_width = 20; mod_type = ModeType.phase_mode; 
        bit_sequence = ""; freq = 100; time_discrete = 0.02;
    }

    override protected GtkAllocation allocatePlotArea(ref Widget w) {
        GtkAllocation w_alloc; ulong act_size = f_width;

        w.setSizeRequest(0, 0); w.getAllocation(w_alloc);

        if(bit_sequence.length != 0) {
            act_size = cast(ulong)(f_width * cast(double)(time_discrete * freq));
            if(act_size < f_width) act_size = f_width;

            w.setSizeRequest(cast(int)(act_size * bit_sequence.length + 65), w_alloc.height);
        } w.getAllocation(w_alloc);

        return w_alloc;
    }

    override protected ulong countXUnitSize(GtkAllocation) @safe {
        ulong x_size = f_width;

        if(bit_sequence.length != 0) {
            x_size = cast(ulong)(f_width * cast(double)(time_discrete * freq));
            if(x_size < f_width) x_size = f_width;
        }

        return cast(ulong)(x_size);
    }

    override protected ulong countYUnitSize(GtkAllocation widget_alloc) @safe {
        return cast(ulong)(widget_alloc.height / 3);
    }

    override protected void drawXAxis(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong, ulong) {
        cairo_context.moveTo(10, widget_alloc.height / 2);
        cairo_context.relLineTo(widget_alloc.width - 20, 0);
        cairo_context.relLineTo(-5, +2);
        cairo_context.relLineTo(+5, -2);
        cairo_context.relLineTo(-5, -2);
        cairo_context.relLineTo(+5, +2);
        cairo_context.stroke();
    }

    override protected void makeXAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong) {
        cairo_context.moveTo(20 + x_size, widget_alloc.height / 2 - 4);
        cairo_context.relLineTo(0, 8);
        if(bit_sequence.length != 0) {
            for(int i = 0; i < bit_sequence.length - 1; i++) {
                cairo_context.relMoveTo(x_size, -8);
                cairo_context.relLineTo(0, 8);
            }
        }
        cairo_context.stroke();
    }

    override protected void makeYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation, ulong, ulong y_size) {
        cairo_context.moveTo(16, y_size / 2);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
        cairo_context.moveTo(16, y_size / 2 * 5);
        cairo_context.relLineTo(8, 0); cairo_context.stroke();
    }

    override protected void textXAxisName(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong, ulong y_size) {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(widget_alloc.width - 30, y_size / 2 * 3 + 15);
        cairo_context.showText("t(сек.)");
    }

    override protected void textYAxisName(ref Scoped!Context cairo_context, GtkAllocation, ulong, ulong) {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(6, 15); cairo_context.showText("А");
    }

    override protected void textXAxisUnits(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong) {
        cairo_context.rotate(3.1415 / 2);
        
        int reveresed_width = -cast(int)(x_size);
        int reveresed_height = widget_alloc.height / 2 + 6;

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

    override protected void textYAxisUnits(ref Scoped!Context cairo_context, GtkAllocation, ulong, ulong y_size) {
        cairo_context.moveTo(5, y_size / 2 + 3);
        cairo_context.showText("1");
        cairo_context.moveTo(5, y_size / 2 * 5 + 3);
        cairo_context.showText("-1");
    }

    override protected void drawPlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        cairo_context.setSourceRgba(line_color.r,
                                    line_color.g,
                                    line_color.b,
                                    line_color.a);

        if(bit_sequence.length == 0) return;

        cairo_context.setLineWidth(1);
        cairo_context.moveTo(20, y_size / 2 * 3);

        switch(mod_type) {
            case ModeType.phase_mode : drawPhasePlotLine(cairo_context, widget_alloc, x_size, y_size); break;
            case ModeType.amplitude_mode : drawAmplitudePlotLine(cairo_context, widget_alloc, x_size, y_size); break;
            case ModeType.frecuency_mode : drawFrequencyPlotLine(cairo_context, widget_alloc, x_size, y_size); break;
            default : break;
        }
    }

    protected void drawPhasePlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(y_size) - cast(double)(x_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw) / 4;
        double cur_x = 0, cur_y = 0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

            for(size_t j = 0; j < need_draw * 2; j++) {
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
            cairo_context.moveTo(20 + x_size * (i + 1), y_size / 2 * 3);
        }
    }

    protected void drawAmplitudePlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw) / 4;
        double cur_x = 0, cur_y = 0, line_height = 0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(bit_sequence[i] == '1') line_height = cast(double)(y_size);
            else line_height = cast(double)(y_size / 2);

            line_height = line_height - del_x_arc;

            for(size_t j = 0; j < need_draw * 2; j++) {
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
            cairo_context.moveTo(20 + x_size * (i + 1), y_size / 2 * 3);
        }
    }

    protected void drawFrequencyPlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw < 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(y_size) - cast(double)(x_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw);
        double cur_x = 0, cur_y = 0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            for(int j = 0; j < need_draw * (bit_sequence[i] == '1' ? 2 : 1); j++) {
                cairo_context.relLineTo(0, (last_state == true ? -line_height : line_height));

                cairo_context.getCurrentPoint(cur_x, cur_y);
                if(last_state)
                    cairo_context.arc(cur_x + del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), cur_y, del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), 3.1415, 3.1415 * 2);
                else 
                    cairo_context.arcNegative(cur_x + del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), cur_y, del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), 3.1415, 3.1415 * 2);

                cairo_context.relLineTo(0, (last_state == true ? line_height : -line_height));
                last_state = !last_state;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + x_size * (i + 1), y_size / 2 * 3);
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
}