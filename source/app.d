module Signal;

import SignalWin;

import gtk.Application;
import gtk.Builder;
import gtk.Main;

import std.system;

void main(string [] args) {
    Main.init(args);

    Application signal_app = new Application("org.signal.kimp", GApplicationFlags.FLAGS_NONE);

    signal_app.addOnActivate((gio.Application.Application) {
        Builder signal_builder = new Builder();
        if(os == OS.linux) signal_builder.addFromResource("/kimp/ui/SiganlWin.glade");
        else signal_builder.addFromFile("res\\SignalWin.glade");

        SignalWin win = new SignalWin(signal_builder, "main_window");
        signal_app.addWindow(win); win.showAll;
    });

    signal_app.run(args);
}