module NoiseRadioPulsePlot;

import RadioPulsePlot;
import Noise;

class NoiseRadioPulsePlot : RadioPulsePlot {
    public this() { super();
        plotName("Полученный сигнал");
    }

    private ulong noise_power;
    @property public ulong noisePower() @safe @nogc { return noise_power; }
    @property public ulong noisePower(ulong pow) @safe @nogc { return noise_power = pow; }

    private AWGNoise plot_noise;
    @property public AWGNoise plotNoise() { return plot_noise; }
    @property public AWGNoise plotNoise(AWGNoise n) { return plot_noise = n; }
}