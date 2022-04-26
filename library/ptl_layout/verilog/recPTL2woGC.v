// jj-tlf
//      2003.5.8 modified by Y. Kameda
//	2003.5.2	by akimoto
//	2007.11.16	by M. Tanaka
//	2008.7.23	by K. Takagi
//	2022.4/26	by T. Kawaguchi

module recPTL2woGC (dout, din);
   output dout;
   input din;

// used only for static timing analysis
parameter bias_voltage =`BV ;
parameter BV80 = 2 ;
parameter  DIN__DOUT__1 = 0 ;
parameter  DIN__DIN__1 = 0 ;
parameter BV130 = 3.25 ;
parameter  DIN__DOUT__2 = 0 ;
parameter  DIN__DIN__2 = 0 ;

parameter	din__dout = 0;

	// __ptl	#(din__dout)	g1(din, dout);

	// used for back-annotation (default delay: 0)
	buf	g1(dout, din);
endmodule
