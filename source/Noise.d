module Noise;

import std.container;
import std.random;
import std.stdio;

class AWGNoise {
    public SList!byte * noise_list;

    public this(uint length = 0, uint max_value = 10) {
        noise_list = new SList!byte;
        if(length != 0) generateAWGNoise(length, max_value);        
    }

    public void generateAWGNoise(uint length, uint max_value = 10) {
        clearNoise();

        byte value = 0, pos = 0;

        for(uint i = 0; i < length; i++) {
            value = cast(byte)uniform!"[]"(0, max_value);
            pos = cast(byte)uniform!"[]"(0, max_value) % 2;

            if(pos) noise_list.insert(value);
            else noise_list.insert(cast(byte)(value * -1));
        }

        debug {
            noise_list.opSlice().writeln();
        }
    }

    public void clearNoise() {
        noise_list.clear();
    }

    public ~this() {
        clearNoise(); noise_list.destroy();
    }
}