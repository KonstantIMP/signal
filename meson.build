project('signal', ['d', 'c'],
        version : '0.0.1')

gnome = import('gnome')

signal_sorce = [
    'source/app.d',
    'source/Noise.d',
    'source/Color.d',
    'source/SignalWin.d',
    'source/PlotViewer.d',
    'source/VideoPulsePlot.d',
    'source/RadioPulsePlot.d',
    'source/NoiseRadioPulsePlot.d'
]
signal_resorce = [
    'resource/signal.gresource.xml'
]

source_root = meson.source_root()
source_dir = include_directories('source/')
resource_dir = 'resource/'

gtkd_dep = dependency('gtk-d:gtkd', method : 'dub')
gtk_dep = dependency('gtk+-3.0')

signal_resorce = [
    gnome.compile_resources('signal_resorce',    
    files([signal_resorce]),
    source_dir : [resource_dir],   
    c_name : 'signal')
]

signal_bin = executable('signal',
    [signal_sorce, signal_resorce],
    include_directories : [source_dir, resource_dir],
    dependencies : [gtkd_dep, gtk_dep])