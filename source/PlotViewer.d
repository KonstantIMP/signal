module PlotViewer;

import gtk.ScrolledWindow;
import gtk.DrawingArea;
import gtk.Overlay;
import gtk.Widget;
import gtk.Label;

import Color;

class PlotViewer : Overlay {    
    public this(immutable string name) {
        super(); plot_name = name;

        axes_color = RgbaColor(0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor(1.0, 1.0, 1.0, 1.0);

        plot_name_msg = new Label("");

        createUI();
    }

    protected void createUI() {
        /// Plot name uses markup for work with text and background colors
        plot_name_msg.setUseMarkup(true);
        plot_name_msg.setMarkup("<span size='small' foreground='#" ~ rgbaToHexStr(axes_color) ~ "'>" ~ plot_name ~ "</span>");

        /// Setting plot_name as OverlayWidget
        addOverlay(cast(Widget)(plot_name_msg));
        /// Setting plot_name position
        plot_name_msg.setProperty("margin", 5);
        plot_name_msg.setProperty("halign", GtkAlign.END);
        plot_name_msg.setProperty("valign", GtkAlign.START); 
    }

    protected string plot_name;

    protected Label plot_name_msg; 

    /// @brief Plot axes color
    private RgbaColor axes_color;
    /// @brief axesColor    Getter for axes_color
    @property RgbaColor axesColor() @trusted @nogc { return axes_color; }
    /// @brief axesColor    Setter for axes_color
    @property RgbaColor axesColor(RgbaColor axes_c) @trusted {
        plot_name_msg.setMarkup("<span size='small' foreground='#" ~ rgbaToHexStr(axes_c) ~ "'>" ~ plot_name ~ "</span>");

        return axes_color = axes_c;    
    }

    /// @brief Plot background color
    protected RgbaColor background_color;
    /// @brief backgroundColor    Getter for background_color
    public @property RgbaColor backgroundColor() @trusted @nogc { return background_color; }
    /// @brief backgroundColor    Setter for background_color
    public @property RgbaColor backgroundColor(RgbaColor back_c) @trusted {
        return background_color = back_c;
    }
}