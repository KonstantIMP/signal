module SignalWin;

extern (C) GObject * gtk_builder_get_object (GtkBuilder * builder, const char * name);

import VideoPulsePlot;
import RadioPulsePlot;

import glib.c.types;
import gtk.c.types;

import gtk.ScrolledWindow;
import gtk.ComboBoxText;
import gtk.EditableIF;
import gtk.Overlay;
import gtk.Widget;
import gtk.Entry;

import gtk.Builder;
import gtk.Window;

import std.ascii;
import std.conv;

import std.stdio;

alias slot = void;

class SignalWin : Window {
    public this(ref Builder _builder, string win_name) @trusted {
        super(cast(GtkWindow *)gtk_builder_get_object(_builder.getBuilderStruct(), win_name.ptr));
        setBorderWidth(10); uiBuilder = _builder;

        initValues(); connectSignals();
    }

    private void initValues() @trusted {
        uiBuilder.getObject("video_msg").setProperty("margin", 5);
        uiBuilder.getObject("video_msg").setProperty("halign", GtkAlign.END);
        uiBuilder.getObject("video_msg").setProperty("valign", GtkAlign.START);
        (cast(Overlay)(uiBuilder.getObject("video_over"))).addOverlay(
            (cast(Widget)(uiBuilder.getObject("video_msg")))
        );
        video_plot = new VideoPulsePlot();
        (cast(ScrolledWindow)(uiBuilder.getObject("video_sw"))).add(video_plot);

        uiBuilder.getObject("radio_msg").setProperty("margin", 5);
        uiBuilder.getObject("radio_msg").setProperty("halign", GtkAlign.END);
        uiBuilder.getObject("radio_msg").setProperty("valign", GtkAlign.START);
        (cast(Overlay)(uiBuilder.getObject("radio_over"))).addOverlay(
            (cast(Widget)(uiBuilder.getObject("radio_msg")))
        );
        radio_plot = new RadioPulsePlot();
        (cast(ScrolledWindow)(uiBuilder.getObject("radio_sw"))).add(radio_plot);
    }

    private void connectSignals() @trusted {
        (cast(EditableIF)(uiBuilder.getObject("informativeness_en"))).addOnChanged(&onDigitEnChanged);
        (cast(EditableIF)(uiBuilder.getObject("frequency_en"))).addOnChanged(&onDigitEnChanged);
        //(cast(Entry)(uiBuilder.getObject("informativeness_en"))).addOnBackspace(&onBackspacePressed);
        //(cast(Entry)(uiBuilder.getObject("frequency_en"))).addOnBackspace(&onBackspacePressed);

        (cast(EditableIF)(uiBuilder.getObject("bit_sequence_en"))).addOnChanged(&onBinaryEnChanged);
        //(cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).addOnBackspace(&onBackspacePressed);

        (cast(ComboBoxText)(uiBuilder.getObject("mod_cb"))).addOnChanged(&onModTypeChanged);
    }

    private void redrawPlot() @trusted {
        video_plot.BitSequence((cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).getText());
        video_plot.TimeDiscrete(1 / to!double((cast(Entry)(uiBuilder.getObject("informativeness_en"))).getText()));

        video_plot.drawRequest();

        radio_plot.BitSequence(video_plot.BitSequence());
        radio_plot.TimeDiscrete(video_plot.TimeDiscrete());
        radio_plot.Frequency(to!(uint)((cast(Entry)(uiBuilder.getObject("frequency_en"))).getText()));

        radio_plot.drawRequest();
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

    protected slot onModTypeChanged(ComboBoxText text_cb) {
        if(text_cb.getActiveId() == "frequency_mod") radio_plot.ModType(modType.frecuency_mod);
        if(text_cb.getActiveId() == "phase_mod") radio_plot.ModType(modType.phase_mod);

        redrawPlot();
    }

    private VideoPulsePlot video_plot;
    private RadioPulsePlot radio_plot;

    private Builder uiBuilder;
}