module SignalWin;

extern (C) GObject * gtk_builder_get_object (GtkBuilder * builder, const char * name);

import glib.c.types;
import gtk.c.types;

import gtk.EditableIF;

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

    }

    private void connectSignals() @trusted {
        (cast(EditableIF)(uiBuilder.getObject("informativeness_en"))).addOnChanged(&onDigitEnChanged);
        (cast(EditableIF)(uiBuilder.getObject("frequency_en"))).addOnChanged(&onDigitEnChanged);

        (cast(EditableIF)(uiBuilder.getObject("bit_sequence_en"))).addOnChanged(&onBinaryEnChanged);
    }

    public slot onDigitEnChanged(EditableIF entry) {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) return;

        if(!isDigit(input_sym[0])) {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }
    }

    public slot onBinaryEnChanged(EditableIF entry) {
        string input_sym = entry.getChars(entry.getPosition(), entry.getPosition() + 1);
        
        if(input_sym.length == 0) return;

        if(input_sym[0] != '0' && input_sym[0] != '1') {
            string correct_out = entry.getChars(0, entry.getPosition()) ~ entry.getChars(entry.getPosition() + 2, -1);

            entry.deleteText(0, -1); int zero = 0;
            entry.insertText(correct_out, cast(int)correct_out.length, zero);
        }
    }

    private Builder uiBuilder;
}