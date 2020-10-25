module SignalWin;

extern (C) GObject * gtk_builder_get_object (GtkBuilder * builder, const char * name);

import VideoPulsePlot;

import glib.c.types;
import gtk.c.types;

import gtk.ScrolledWindow;
import gtk.EditableIF;
import gtk.Entry;

import gtk.Builder;
import gtk.Window;

import std.ascii;

alias slot = void;

class SignalWin : Window {
    public this(ref Builder _builder, string win_name) @trusted {
        super(cast(GtkWindow *)gtk_builder_get_object(_builder.getBuilderStruct(), win_name.ptr));
        setBorderWidth(10); uiBuilder = _builder;

        initValues(); connectSignals();
    }

    private void initValues() @trusted {
        video_plot = new VideoPulsePlot();
        (cast(ScrolledWindow)(uiBuilder.getObject("video_sw"))).add(video_plot);
    }

    private void connectSignals() @trusted {
        (cast(EditableIF)(uiBuilder.getObject("informativeness_en"))).addOnChanged(&onDigitEnChanged);
        (cast(EditableIF)(uiBuilder.getObject("frequency_en"))).addOnChanged(&onDigitEnChanged);
        (cast(Entry)(uiBuilder.getObject("informativeness_en"))).addOnBackspace(&onBackspacePressed);
        (cast(Entry)(uiBuilder.getObject("frequency_en"))).addOnBackspace(&onBackspacePressed);

        (cast(EditableIF)(uiBuilder.getObject("bit_sequence_en"))).addOnChanged(&onBinaryEnChanged);
        (cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).addOnBackspace(&onBackspacePressed);
    }

    private void redrawPlot() @trusted {
        video_plot.BitSequence((cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).getText());

        video_plot.drawRequest();
    }

    protected slot onDigitEnChanged(EditableIF entry) @trusted {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) return;

        if(!isDigit(input_sym[0])) {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }

        redrawPlot();
    }

    protected slot onBinaryEnChanged(EditableIF entry) @trusted {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) return;

        if(input_sym[0] != '0' && input_sym[0] != '1') {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }

        redrawPlot();
    }

    protected slot onBackspacePressed(Entry en) {
        

        redrawPlot();
    }

    private VideoPulsePlot video_plot;

    private Builder uiBuilder;
}