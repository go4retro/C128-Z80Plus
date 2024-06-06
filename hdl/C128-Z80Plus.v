`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:40:22 06/05/2024 
// Design Name: 
// Module Name:    C128-Z80Plus 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module C128_Z80Plus(
							input CLK1MHZ,			/* U12 pin 11, Z80 is active on low phase of the system clock */
							input CLKDOT,			/* 8MHz dot clock from expansion port pin 6 */
							input CLKZ80,			/* Z80 socket pin 6, original clock */
							input nMREQ,			/* Z80 pin 19, memory request */
							input nIORQ,			/* Z80 pin 20, I/O request */
							//input nBUSRQ,			/* bus request from VIC(?) or bus disconnect when 6502 is active */
							//input nBUSACK,	 		/* Z80 ack for bus request */
							//input nM1,		 		/* first machine cycle */
							input nRFSH,			/* Z80 pin 28, if active: the MREQ request is memory refresh, ignore */
							input nRESET,			/* Z80 pin 26 */
							input nWR,				/* Z80 pin 22, (active one cycle later than MREQ, without delay with IORQ) */
							input CLOCKSEL,   	/* jumper for clock selection: open (internal pullup) = FAST, closed to GND = SLOW */
							output CLKOUT,			/* Z80 pin 6, clock, 4/8 MHz half of the time */
							output WAIT				/* Z80 pin 24 */
    );
	 
 reg WAITLATCH;

/** Logic Equations **/

/* output 8MHz during CLK1MHZ low phase and no memory request */
/* hold low during CLK1MHZ low phase and memory write request, until next 1MHz clock tick */
/* output mainboard clock CLKIN if CLOCKSEL is grounded */

assign CLKOUT = (  nRESET &  CLOCKSEL & !CLK1MHZ &  nMREQ &  nWR & !CLKDOT ) 
					 | (nRESET &  CLOCKSEL & !CLK1MHZ &  nMREQ & !nWR & !CLKDOT )
				    | (nRESET &  CLOCKSEL & !CLK1MHZ & !nMREQ & !nWR )
					 | (nRESET &  CLOCKSEL & !CLK1MHZ & !nMREQ &  nWR & !CLKDOT )
					 | (nRESET & !CLOCKSEL & CLKZ80 );

/* reset latch when going into VIC phase, keep that line high during Z80 phase */
assign WAITRESET = !nRESET | !CLK1MHZ;

/* trigger latch on any address bus request: I/O or memory but not during memory refresh */
assign WAITTRIGGER = nRESET & nRFSH & (!nMREQ | !nIORQ);

/* copy latched wait status to Z80 /WAIT input or keep it high when slow mode is selected */
assign WAIT = CLOCKSEL & WAITLATCH | !CLOCKSEL;

always @(posedge WAITTRIGGER)
begin
	if(WAITRESET)
		WAITLATCH <= 1;
	else
		WAITLATCH <= 0;
end

endmodule
