/// @file   VideoPulsePlot.d
/// 
/// @brief  VideoPulsePlot class description
///
/// @license LGPLv3 (see LICENSE file)
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
import std.conv;

import PlotViewer;
import Color;

class VideoPulsePlot : PlotViewer {
    public this() { super("График видеоимпульса");
        min_x_width = 30; max_x_width = 50;
        bit_sequence = ""; time_discrete = 0.02;
    }

    override protected GtkAllocation allocatePlotArea(ref Widget w) {
        GtkAllocation w_alloc; ulong act_size = max_x_width;

        w.setSizeRequest(0, 0); w.getAllocation(w_alloc);

        if(bit_sequence.length != 0) {
            act_size = (w_alloc.width - 65) / bit_sequence.length;

            if(act_size > max_x_width) act_size = max_x_width;
            else if(act_size < min_x_width) act_size = min_x_width;

            if(to!string(time_discrete).length * 5 + 15 > act_size) act_size = to!string(time_discrete).length * 5 + 15;

            w.setSizeRequest(cast(int)(act_size * bit_sequence.length + 65), w_alloc.height);
        } w.getAllocation(w_alloc);

        return w_alloc;
    }

    override protected ubyte countXUnitSize(GtkAllocation widget_alloc) @safe {
        ulong x_size = max_x_width;

        if(bit_sequence.length != 0) {
            x_size = (widget_alloc.width - 65) / bit_sequence.length;

            if(x_size > max_x_width) x_size = max_x_width;
            if(x_size < min_x_width) x_size = min_x_width;

            if(to!string(time_discrete).length * 5 + 15 > x_size) x_size = to!string(time_discrete).length * 5 + 15;
        }

        return cast(ubyte)(x_size);
    }

    override protected ubyte countYUnitSize(GtkAllocation widget_alloc) @safe {
        return cast(ubyte)((widget_alloc.height / 2) - 20);
    }

    override protected void makeXAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte x_size, ubyte) {
        cairo_context.moveTo(20 + x_size, widget_alloc.height - 16);
        cairo_context.relLineTo(0, -8);

        if(bit_sequence.length != 0) {
            for(size_t i = 0; i < bitSequence.length - 1; i++) {
                cairo_context.relMoveTo(x_size, 8);
                cairo_context.relLineTo(0, -8);
            }
        }

        cairo_context.stroke();
    }

    override protected void makeYAxisMarkup(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte, ubyte y_size) {
        cairo_context.moveTo(16, y_size + 20);
        cairo_context.relLineTo(8, 0);
        cairo_context.stroke();
    }

    override protected void textXAxisName(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte, ubyte) {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(widget_alloc.width - 30, widget_alloc.height - 5);
        cairo_context.showText("t(сек.)");
    }

    override protected void textYAxisName(ref Scoped!Context cairo_context, GtkAllocation, ubyte, ubyte) {
        cairo_context.setFontSize(10);
        cairo_context.moveTo(6, 15); cairo_context.showText("А");
    }

    override protected void textXAxisUnits(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte x_size, ubyte) {
        cairo_text_extents_t text_extent;

        cairo_context.textExtents(to!string(time_discrete), &text_extent);
        cairo_context.moveTo(20 + x_size - text_extent.width / 2, widget_alloc.height - 5);
        cairo_context.showText(to!string(time_discrete));

        if(bit_sequence.length != 0) {
            double act_time = time_discrete * 2;

            for(size_t i = 0; i < bit_sequence.length - 1; i++) {
                cairo_context.textExtents(to!string(act_time), &text_extent);
                cairo_context.moveTo(20 + (x_size * (i + 2)) - text_extent.width / 2, widget_alloc.height - 5);
                cairo_context.showText(to!string(act_time));
                act_time = act_time + time_discrete;
            }
        }
    }

    override protected void textYAxisUnits(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte, ubyte y_size) {
        cairo_context.moveTo(5, y_size + 23);
        cairo_context.showText("1");
    }

    override protected void drawPlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ubyte x_size, ubyte y_size) {
        cairo_context.setSourceRgba(line_color.r,
                                    line_color.g,
                                    line_color.b,
                                    line_color.a);

        if(bit_sequence.length == 0) return;

        if(bit_sequence[0] == '1') cairo_context.moveTo(20, 20 + y_size);
        else cairo_context.moveTo(20, widget_alloc.height - 20);

        cairo_context.relLineTo(x_size, 0);

        for(size_t i = 1; i < bit_sequence.length; i++) {
            if(bit_sequence[i - 1] != bit_sequence[i]) {
                cairo_context.relLineTo(0, (bit_sequence[i] == '1' ? -(cast(byte)(y_size)) : y_size));                    
            }
            cairo_context.relLineTo(x_size, 0);
        }

        if(bit_sequence[bit_sequence.length - 1] == '1') {
            cairo_context.relLineTo(0, y_size);
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
}