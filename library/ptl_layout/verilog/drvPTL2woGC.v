// jj-tlf
//	2005.1.13	by T. Yamada
//	2008.7/13	by K. Takagi
//	2022.4/26	by T. Kawaguchi

//	`define BV 2.5

module drvPTL2woGC (dout, din);
    output dout;
    input din;
    
parameter bias_voltage =`BV ;
parameter BV80 = 2 ;
parameter  DIN__DOUT__3 = 10.82 ;
parameter  DIN__DIN__3 = 10.82 ;
parameter BV85 = 2.125 ;
parameter  DIN__DOUT__4 = 9.72 ;
parameter  DIN__DIN__4 = 9.72 ;
parameter BV90 = 2.25 ;
parameter  DIN__DOUT__5 = 8.62 ;
parameter  DIN__DIN__5 = 8.62 ;
parameter BV95 = 2.375 ;
parameter  DIN__DOUT__6 = 8.02 ;
parameter  DIN__DIN__6 = 8.02 ;
parameter BV100 = 2.5 ;
parameter  DIN__DOUT__7 = 7.42 ;
parameter  DIN__DIN__7 = 7.42 ;
parameter BV105 = 2.625 ;
parameter  DIN__DOUT__8 = 7.05 ;
parameter  DIN__DIN__8 = 7.05 ;
parameter BV110 = 2.75 ;
parameter  DIN__DOUT__9 = 6.57 ;
parameter  DIN__DIN__9 = 6.57 ;
parameter BV115 = 2.875 ;
parameter  DIN__DOUT__10 = 6.25 ;
parameter  DIN__DIN__10 = 6.25 ;
parameter BV120 = 3 ;
parameter  DIN__DOUT__11 = 5.75 ;
parameter  DIN__DIN__11 = 5.75 ;
parameter BV125 = 3.125 ;
parameter  DIN__DOUT__12 = 5.47 ;
parameter  DIN__DIN__12 = 5.47 ;

	__jtl	#(bias_voltage, 
		BV80, DIN__DOUT__3, DIN__DIN__3,
		BV85, DIN__DOUT__4, DIN__DIN__4,
		BV90, DIN__DOUT__5, DIN__DIN__5,
		BV95, DIN__DOUT__6, DIN__DIN__6,
		BV100, DIN__DOUT__7, DIN__DIN__7,
		BV105, DIN__DOUT__8, DIN__DIN__8,
		BV110, DIN__DOUT__9, DIN__DIN__9,
		BV115, DIN__DOUT__10, DIN__DIN__10,
		BV120, DIN__DOUT__11, DIN__DIN__11,
		BV125, DIN__DOUT__12, DIN__DIN__12)	g1(din, dout);
endmodule
