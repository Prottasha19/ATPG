# Automatic Test Pattern Generation (ATPG)

The TetraMax from synopsys to create the test patterns

Before starting the DFT synthesis, the design must be modify by adding some scan input and output pins. In addition to that, some different design styles such as gated clocks should be followed.

There are many options which should be set to configure the DFT. Among all options, usually we set the clock, test period, type of scan cells, the reset, scan input and output, scan enable and test mode. There are three widly used scan cells, Muxed-D Scan Cell, Clocked Scan Cell and LSSD Scan Cell. Muxed-D scan cells are preferable.
