module SignalWin;

extern (C) GObject * gtk_builder_get_object (GtkBuilder * builder, const char * name);

import VideoPulsePlot;
import RadioPulsePlot;

import glib.c.types;
import gtk.c.types;

import gdkpixbuf.Pixbuf;

import gtk.ScrolledWindow;
import gtk.ComboBoxText;
import gtk.EditableIF;
import gtk.Overlay;
import gtk.Widget;
import gtk.Entry;
import gtk.Grid;

import gtk.Builder;
import gtk.Window;

import std.ascii;
import std.conv;

import std.stdio;
import std.system;

alias slot = void;

class SignalWin : Window {
    public this(ref Builder _builder, string win_name) @trusted {
        super(cast(GtkWindow *)gtk_builder_get_object(_builder.getBuilderStruct(), win_name.ptr));
        setBorderWidth(10); uiBuilder = _builder;

        if(os == OS.linux) setIcon(Pixbuf.newFromResource("/kimp/ui/SignalLogo.png", 128, 128, true));
        else setIcon(new Pixbuf("res\\SignalLogo.png", 128, 128, true));

        video_plot = new VideoPulsePlot();
        radio_plot = new RadioPulsePlot();

        initValues(); connectSignals();
    }

    private void initValues() @trusted {
        (cast(Grid)(uiBuilder.getObject("main_grid"))).attach(video_plot, 4, 0, 8, 4);
        (cast(Grid)(uiBuilder.getObject("main_grid"))).attach(radio_plot, 4, 4, 8, 4);
    }

    private void connectSignals() @trusted {
        (cast(EditableIF)(uiBuilder.getObject("informativeness_en"))).addOnChanged(&onDigitEnChanged);
        (cast(EditableIF)(uiBuilder.getObject("frequency_en"))).addOnChanged(&onDigitEnChanged);
        (cast(Entry)(uiBuilder.getObject("informativeness_en"))).addOnBackspace(&onBackspacePressed);
        (cast(Entry)(uiBuilder.getObject("frequency_en"))).addOnBackspace(&onBackspacePressed);

        (cast(EditableIF)(uiBuilder.getObject("bit_sequence_en"))).addOnChanged(&onBinaryEnChanged);
        (cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).addOnBackspace(&onBackspacePressed);

        (cast(ComboBoxText)(uiBuilder.getObject("mod_cb"))).addOnChanged(&onModeTypeChanged);
    }

    private void redrawPlot() @trusted {
        video_plot.bitSequence((cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).getText());
        video_plot.timeDiscrete(1 / to!double((cast(Entry)(uiBuilder.getObject("informativeness_en"))).getText()));

        video_plot.drawRequest();

        radio_plot.bitSequence(video_plot.bitSequence());
        radio_plot.timeDiscrete(video_plot.timeDiscrete());
        radio_plot.frequency(to!(ulong)((cast(Entry)(uiBuilder.getObject("frequency_en"))).getText()));

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
        //writeln("Aaa");
        redrawPlot();
    }

    protected slot onModeTypeChanged(ComboBoxText text_cb) {
        if(text_cb.getActiveId() == "frequency_mode") radio_plot.modeType(ModeType.frecuency_mode);
        else if(text_cb.getActiveId() == "phase_mode") radio_plot.modeType(ModeType.phase_mode);
        else radio_plot.modeType(ModeType.amplitude_mode);

        redrawPlot();
    }

    private VideoPulsePlot video_plot;
    private RadioPulsePlot radio_plot;

    private Builder uiBuilder;
}