/// @file   SignalWin.d
///
/// @brief  Main app window
///
/// @license LGPLv3 (see LICENSE file)
/// @author KonstantIMP
/// @date   2020
module SignalWin;

import VideoPulsePlot;
import RadioPulsePlot;

import PlotViewer;

import Noise;

import glib.c.types;
import gtk.c.types;

import gdkpixbuf.Pixbuf;

import gtk.ScrolledWindow;
import gtk.ComboBoxText;
import gtk.MessageDialog;
import gtk.EditableIF;
import gtk.Overlay;
import gtk.Widget;
import gtk.Entry;
import gtk.Grid;

import gtk.Builder;
import gtk.Window;

import std.ascii;
import std.conv;

import std.system;

import std.stdio;

import Color;

/// @brief  SignalWin   Main program window
///
/// Comtains all UI elements
class SignalWin : Window {
    /// @brief  Basic constructor for widget
    /// Init child widgets, build ui and connect signals
    public this(ref Builder _builder, string win_name) @trusted {
        super((cast(Window)_builder.getObject(win_name)).getWindowStruct());
        setBorderWidth(10); uiBuilder = _builder;

        try {
            if(os == OS.linux) setIcon(Pixbuf.newFromResource("/kimp/ui/SignalLogo.png", 128, 128, true));
            else setIcon(new Pixbuf("..\\res\\SignalLogo.png", 128, 128, true));
        }   
        catch(Exception) {
            MessageDialog war = new MessageDialog(this, GtkDialogFlags.MODAL | GtkDialogFlags.USE_HEADER_BAR,
                    GtkMessageType.WARNING, GtkButtonsType.OK, "Hello!\nThere was a problem(not critical) loading resources!\nReinstall program to solve program...", null);
            war.showAll(); war.run(); war.destroy();
        }

        video_plot = new VideoPulsePlot();
        radio_plot = new RadioPulsePlot();

        //writeln(rgbaToHexStr(video_plot.axesColor()));


        initValues(); connectSignals();
    }

    /// @brief initValues   Put plot widgets to main grid
    private void initValues() @trusted {
        (cast(Grid)(uiBuilder.getObject("main_grid"))).attach(video_plot, 4, 0, 8, 4);
        (cast(Grid)(uiBuilder.getObject("main_grid"))).attach(radio_plot, 4, 4, 8, 4);

        a = new PlotViewer("test"); a.plotName("hiihi");
        (cast(Grid)(uiBuilder.getObject("main_grid"))).attach(a, 4, 8, 8, 4);
    }

    /// @brief connectSignals Connect Signals for entries and ComboBox
    private void connectSignals() @trusted {
        (cast(EditableIF)(uiBuilder.getObject("informativeness_en"))).addOnChanged(&onDigitEnChanged);
        (cast(EditableIF)(uiBuilder.getObject("frequency_en"))).addOnChanged(&onDigitEnChanged);

        (cast(EditableIF)(uiBuilder.getObject("bit_sequence_en"))).addOnChanged(&onBinaryEnChanged);

        (cast(ComboBoxText)(uiBuilder.getObject("mod_cb"))).addOnChanged(&onModeTypeChanged);
    }

    /// @brief redrawPlot   Collect data from entries and sent draw requests
    private void redrawPlot() @trusted {
        if((cast(Entry)(uiBuilder.getObject("informativeness_en"))).getText() == "" ||
           (cast(Entry)(uiBuilder.getObject("frequency_en"))).getText() == "") return;

        if((cast(Entry)(uiBuilder.getObject("informativeness_en"))).getText()[0] == '0' ||
           (cast(Entry)(uiBuilder.getObject("frequency_en"))).getText()[0] == '0') return;

        video_plot.bitSequence((cast(Entry)(uiBuilder.getObject("bit_sequence_en"))).getText());
        video_plot.timeDiscrete(1 / to!double((cast(Entry)(uiBuilder.getObject("informativeness_en"))).getText()));

        video_plot.drawRequest();

        radio_plot.bitSequence(video_plot.bitSequence());
        radio_plot.timeDiscrete(video_plot.timeDiscrete());
        radio_plot.frequency(to!(ulong)((cast(Entry)(uiBuilder.getObject("frequency_en"))).getText()));

        radio_plot.drawRequest();
    }

    /// @brief onDigitEnChanged Doesn't allow input non-Digits to informativity and frequency
    protected void onDigitEnChanged(EditableIF entry) @trusted {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) {
            redrawPlot(); return;
        }

        if(!isDigit(input_sym[0])) {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }

        redrawPlot();
    }

    /// @brief onBinaryEnChanged Doesn't allow input non-1 and no-0 to bit sequence
    protected void onBinaryEnChanged(EditableIF entry) @trusted {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) {
            redrawPlot(); return;
        }

        if(input_sym[0] != '0' && input_sym[0] != '1') {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }

        redrawPlot();
    }

    /// @brief onModeTypeChanged Change RadioPlot modulation type
    protected void onModeTypeChanged(ComboBoxText text_cb) {
        if(text_cb.getActiveId() == "frequency_mode") radio_plot.modeType(ModeType.frecuency_mode);
        else if(text_cb.getActiveId() == "phase_mode") radio_plot.modeType(ModeType.phase_mode);
        else radio_plot.modeType(ModeType.amplitude_mode);

        redrawPlot();
    }

    /// @brief Video plot widget
    private VideoPulsePlot video_plot;
    /// @brief Radio plot widget
    private RadioPulsePlot radio_plot;

    /// @brief UI builder object
    private Builder uiBuilder;

    private PlotViewer a;
}