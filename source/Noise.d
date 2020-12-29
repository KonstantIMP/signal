module Noise;

import std.exception;
import std.random;
import std.stdio;

class AWGNoise {
    private byte [] noise_list;

    public this(uint length = 0, byte max_value = 10) {
        noise_list = null;
        if(length != 0) generateAWGNoise(length, max_value);        
    }

    public void generateAWGNoise(uint length, byte max_value = 10) {
        if(noise_list !is null) noise_list.destroy();
        noise_list = new byte[length];

        byte value = 0, pos = 0;

        for(uint i = 0; i < length; i++) {
            value = cast(byte)uniform!"[]"(0, max_value);
            pos = cast(byte)uniform!"[]"(0, max_value) % 2;

            if(pos) noise_list[i] = value;
            else noise_list[i] = cast(byte)(value * -1);
        }

        debug {
            noise_list.writeln();
        }
    }

    public size_t getNoiseLength() {
        if(noise_list is null) return 0;
        return noise_list.length;
    }

    public byte at(size_t index) {
        enforce(index < noise_list.length, "BadAlloc : noise array is smaller than index value");
        enforce(noise_list !is null, "Error : Noise hasn`t been generated yet");
        return noise_list[index];
    }

    public ~this() {
        if(noise_list !is null) noise_list.destroy();
    }
}