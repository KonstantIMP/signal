module PlotViewer;

import gtk.ScrolledWindow;
import gtk.DrawingArea;
import gtk.Overlay;
import gtk.Widget;
import gtk.Label;

import Color;

alias void slot;

class PlotViewer : Overlay {  
    /// @brief  Basic constructor for widget
    /// Init child widgets, build ui and connect signals  
    public this(immutable string name) {
        super(); plot_name = name;

        plot_area = new DrawingArea();
        plot_name_msg = new Label("");
        plot_sw = new ScrolledWindow();

        line_color = RgbaColor(0.0, 1.0, 0.0, 1.0);
        axes_color = RgbaColor(0.0, 0.0, 0.0, 1.0);
        background_color = RgbaColor(1.0, 1.0, 1.0, 1.0);  

        createUI(); connectSignals();
    }

    /// @brief drawRequest  Request plot area redraw at GTK
    public void drawRequest() @trusted {
        /// Set plot area size as zeroes for smart plot scale
        plot_area.setSizeRequest(0, 0);
        plot_area.queueDraw();
    }

    /// @brief createUI Setting correct ui struct
    protected void createUI() {
        /// Adding plot_sw to Overlay(child)
        add(cast(Widget)(plot_sw));
        /// Adding plot_area to ScrolledWindow(child)
        plot_sw.add(cast(Widget)(plot_area)); 

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

    protected void connectSignals() {
        plot_area.addOnDraw(&onDraw);
    }

    /// @brief onDraw   Plot drawing slot
    /// This slot is called every time plot redraw
    ///
    /// @param[in]  _context    Cairo context for actually draw
    /// @param[in]  _widget     Widget that contains cairo surface for drawing
    ///
    /// @return     bool        True if drawing was succesfull
    protected slot onDraw(Scoped!Context _context, Widget _widget) {
        
    }

    protected Label plot_name_msg;
    protected DrawingArea plot_area;
    protected ScrolledWindow plot_sw;

    /// @brief Plot name
    protected string plot_name;
    /// @brief plotName Getter for plot_name
    public @property string plotName() @safe @nogc { return plot_name; }
    /// @brief plotName Setter for plot_name
    public @property string plotName(string name) @trusted {
        plot_name_msg.setMarkup("<span size='small' foreground='#" ~ rgbaToHexStr(axes_color) ~ "'>" ~ name ~ "</span>");
        return plot_name = name;
    }

    /// @brief Plot line color
    protected RgbaColor line_color;
    /// @brief lineColor    Getter for line_color
    public @property RgbaColor lineColor() @safe @nogc { return line_color; }
    /// @brief lineColor    Setter for line_color
    public @property RgbaColor lineColor(RgbaColor line_c) @safe @nogc { return line_color = line_c; }

    /// @brief Plot axes color
    protected RgbaColor axes_color;
    /// @brief axesColor    Getter for axes_color
    public @property RgbaColor axesColor() @safe @nogc { return axes_color; }
    /// @brief axesColor    Setter for axes_color
    public @property RgbaColor axesColor(RgbaColor axes_c) @trusted {
        plot_name_msg.setMarkup("<span size='small' foreground='#" ~ rgbaToHexStr(axes_c) ~ "'>" ~ plot_name ~ "</span>");
        return axes_color = axes_c;    
    }

    /// @brief Plot background color
    protected RgbaColor background_color;
    /// @brief backgroundColor    Getter for background_color
    public @property RgbaColor backgroundColor() @safe @nogc { return background_color; }
    /// @brief backgroundColor    Setter for background_color
    public @property RgbaColor backgroundColor(RgbaColor back_c) @safe {
        return background_color = back_c;
    }
}