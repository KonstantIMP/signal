module NoiseRadioPulsePlot;

import cairo.Context;
import gtk.c.types;

import std.math;
import std.conv;

import RadioPulsePlot;
import Noise;

class NoiseRadioPulsePlot : RadioPulsePlot {
    public this() { super();
        plotName("Полученный сигнал");
    }

    override protected void drawPhasePlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        //AAAAA I don't know how
        /*uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(y_size) - cast(double)(x_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw) / 4;
        double cur_x = 0, cur_y = 0;

        ulong counter = 0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

            for(size_t j = 0; j < need_draw * 2; j++) {
                cairo_context.relLineTo(0.5, (last_state == true ? -line_height : line_height));
                counter++;

                cairo_context.getCurrentPoint(cur_x, cur_y);

                if(last_state) {
                    //cairo_context.arc(cur_x + del_x_arc, cur_y, del_x_arc, 3.1415, 3.1415 * 2);
                    cairo_context.relCurveTo(0, -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             del_x_arc / 2, plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             del_x_arc / 2, plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             -del_x_arc / 2, -plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             +del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             -del_x_arc / 2, -plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             +del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;
                }                    
                else {
                    cairo_context.relCurveTo(0, del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             -del_x_arc / 2, -plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             +del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             -del_x_arc / 2, -plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             +del_x_arc - plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             del_x_arc / 2, plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;

                    cairo_context.relCurveTo(0, -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()),
                                             del_x_arc / 2, plot_noise.at(counter % plot_noise.getNoiseLength()), del_x_arc / 2 - 0.25,
                                             -del_x_arc + plot_noise.at(counter % plot_noise.getNoiseLength()));

                    counter++;
                }

                cairo_context.relLineTo(0.5, (last_state == true ? line_height : -line_height));
                last_state = !last_state;
            }
        }

        cairo_context.stroke();*/
    }

    private ulong noise_power;
    @property public ulong noisePower() @safe @nogc { return noise_power; }
    @property public ulong noisePower(ulong pow) @safe @nogc { return noise_power = pow; }

    private AWGNoise plot_noise;
    @property public AWGNoise plotNoise() { return plot_noise; }
    @property public AWGNoise plotNoise(AWGNoise n) { return plot_noise = n; }
}