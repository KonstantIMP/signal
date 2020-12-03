/// @file   app.d
///
/// @brief  Main function for signal app
///
/// @license LGPLv3 (see LICENSE file)
/// @author KonstantIMP
/// @date   2020
module Signal;

import SignalWin;

import gtk.Application;
import gtk.MessageDialog;
import gtk.Builder;
import gtk.Main;

import core.stdc.stdlib;
import std.system;

/// @brief main signal function
///
/// param[in] args Input parametrs
int main(string [] args) {
    /// Init GTKd
    Main.init(args);

    /// Register application
    Application signal_app = new Application("org.signal.kimp", GApplicationFlags.FLAGS_NONE);

    /// When application is ready
    signal_app.addOnActivate((gio.Application.Application) {
        /// Load UI from .glade file
        Builder signal_builder = new Builder();        
        try {
            if(os == OS.linux) signal_builder.addFromResource("/kimp/ui/SignalWin.glade");
            else signal_builder.addFromFile("res\\SignalWin.glade");
        }
        catch(Exception) {
            /// Error while loading .glade file
            MessageDialog err = new MessageDialog(null, GtkDialogFlags.MODAL | GtkDialogFlags.USE_HEADER_BAR,
                    GtkMessageType.ERROR, GtkButtonsType.OK, "Hello!\nThere was a problem loading resources!\nReinstall program to solve program...", null);
            signal_app.addWindow(err); err.showAll(); err.run();
            err.destroy();

            exit(-1);
        }

        /// Create window
        SignalWin win = new SignalWin(signal_builder, "main_window");
        signal_app.addWindow(win); win.showAll();
    });

    /// Start programm
    signal_app.run(args);
    return 0;
}