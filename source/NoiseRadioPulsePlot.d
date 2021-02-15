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
        noise_power = 100;
    }

    override protected void drawPhasePlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(y_size) - cast(double)(x_size) / cast(double)(need_draw) / 4;

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw) / 4;

        ulong counter = 0; double affective_power = cast(double)(noise_power) / 100.0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(i != 0 && bit_sequence[i - 1] != bit_sequence[i]) last_state = !last_state;

            for(size_t j = 0; j < need_draw * 2; j++) {
                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, (last_state == true ? -line_height : line_height));
                counter += 2;

                if(last_state) drawArc(cairo_context, del_x_arc, counter);       
                else drawNegativeArc(cairo_context, del_x_arc, counter);

                counter += 8;

                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, (last_state == true ? line_height : -line_height));
                last_state = !last_state; counter += 2;
            }
        }

        cairo_context.stroke();
    }

    override protected void drawAmplitudePlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw == 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw) / 4;
        double line_height = 0;

        ulong counter = 0; double affective_power = cast(double)(noise_power) / 100.0;

        for(size_t i = 0; i < bit_sequence.length; i++) {
            if(bit_sequence[i] == '1') line_height = cast(double)(y_size);
            else line_height = cast(double)(y_size / 2);

            line_height = line_height - del_x_arc;

            for(size_t j = 0; j < need_draw * 2; j++) {
                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, line_height * (last_state == true ? -1 : 1));
                counter += 2;

                if(last_state) drawArc(cairo_context, del_x_arc, counter);
                else drawNegativeArc(cairo_context, del_x_arc, counter);
                
                counter += 8;

                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, line_height * (last_state == true ? 1 : -1));
                last_state = !last_state; counter += 2;
            }
        } cairo_context.stroke();
    }

    override protected void drawFrequencyPlotLine(ref Scoped!Context cairo_context, GtkAllocation widget_alloc, ulong x_size, ulong y_size) {
        uint need_draw = cast(uint)(round(time_discrete * freq));
        bool last_state = true;

        if(need_draw < 0) {
            time_discrete = time_discrete + time_discrete;
            drawRequest(); return;
        }

        double line_height = cast(double)(y_size) - cast(double)(x_size) / cast(double)(need_draw) / 4;
        ulong counter = 0; double affective_power = cast(double)(noise_power) / 100.0;
        double del_x_arc = cast(double)(x_size) / cast(double)(need_draw);

        for(size_t i = 0; i < bit_sequence.length; i++) {
            for(int j = 0; j < need_draw * (bit_sequence[i] == '1' ? 2 : 1); j++) {
                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, (last_state == true ? -line_height : line_height));
                counter += 2;

                if(last_state) drawArc(cairo_context, del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), counter);
                else drawNegativeArc(cairo_context, del_x_arc / (bit_sequence[i] == '1' ? 4 : 2), counter);

                counter += 4;

                cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                         0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                         0.5, (last_state == true ? line_height : -line_height));
                last_state = !last_state; counter += 2;
            }

            cairo_context.stroke();
            cairo_context.moveTo(20 + x_size * (i + 1), y_size / 2 * 3);
        }
    }

    private void drawArc(ref Scoped!Context cairo_context, double del_x_arc, ulong counter) {
        double affective_power = cast(double)(noise_power) / 100.0;
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, -del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 3) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 4) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, -del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 5) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 6) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 7) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 8) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, del_x_arc);
    }

    private void drawNegativeArc(ref Scoped!Context cairo_context, double del_x_arc, ulong counter) {
        double affective_power = cast(double)(noise_power) / 100.0;
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 1) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 2) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 3) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 4) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 5) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 6) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, -del_x_arc);
        cairo_context.relCurveTo(0, cast(double)(plot_noise.at((counter + 7) % plot_noise.getNoiseLength()) * affective_power),
                                 0, cast(double)(plot_noise.at((counter + 8) % plot_noise.getNoiseLength()) * affective_power),
                                 del_x_arc / 2 - 0.25, -del_x_arc);
    }

    private ulong noise_power;
    @property public ulong noisePower() @safe @nogc { return noise_power; }
    @property public ulong noisePower(ulong pow) @safe @nogc { return noise_power = pow; }

    private AWGNoise plot_noise;
    @property public AWGNoise plotNoise() { return plot_noise; }
    @property public AWGNoise plotNoise(AWGNoise n) { return plot_noise = n; }
}