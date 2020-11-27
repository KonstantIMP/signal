module Signal;

import SignalWin;

import gtk.Application;
import gtk.MessageDialog;
import gtk.Builder;
import gtk.Main;

import core.stdc.stdlib;
import std.system;

int main(string [] args) {
    Main.init(args);

    Application signal_app = new Application("org.signal.kimp", GApplicationFlags.FLAGS_NONE);

    signal_app.addOnActivate((gio.Application.Application) {
        Builder signal_builder = new Builder();
        
        try {
            if(os == OS.linux) signal_builder.addFromResource("/kimp/ui/SignalWin.glade");
            else signal_builder.addFromFile("res\\SignalWin.glade");
        }
        catch(Exception) {
            MessageDialog err = new MessageDialog(null, GtkDialogFlags.MODAL | GtkDialogFlags.USE_HEADER_BAR,
                    GtkMessageType.ERROR, GtkButtonsType.OK, "Hello!\nThere was a problem loading resources!\nReinstall program to solve program...", null);
            signal_app.addWindow(err); err.showAll(); err.run();
            err.destroy();

            exit(-1);
        }

        SignalWin win = new SignalWin(signal_builder, "main_window");
        signal_app.addWindow(win); win.showAll();
    });

    signal_app.run(args);
    return 0;
}