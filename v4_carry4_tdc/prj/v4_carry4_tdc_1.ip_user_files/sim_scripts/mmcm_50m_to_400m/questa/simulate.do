onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib mmcm_50m_to_400m_opt

do {wave.do}

view wave
view structure
view signals

do {mmcm_50m_to_400m.udo}

run -all

quit -force
