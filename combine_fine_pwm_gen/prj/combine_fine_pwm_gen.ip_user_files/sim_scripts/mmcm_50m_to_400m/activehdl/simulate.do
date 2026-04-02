onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+mmcm_50m_to_400m -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.mmcm_50m_to_400m xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {mmcm_50m_to_400m.udo}

run -all

endsim

quit -force
