// jj-tlf
//	2002.5.20	yamanashi
//	2005.6.1	T. Yamada
//	2008.7.23	K. Takagi
//	2022.4/26	by T. Kawaguchi

module pspl2woGC (b, c, a);
    output b;
    output c;
    input a;

parameter bias_voltage =`BV ; 
parameter BV70 = 1.75 ;
parameter  A__B__1 = 16.49 ;
parameter  A__C__1 = 16.49 ;
parameter  A__A__1 = 5 ;
parameter BV75 = 1.875 ;
parameter  A__B__2 = 13.48 ;
parameter  A__C__2 = 13.48 ;
parameter  A__A__2 = 5 ;
parameter BV80 = 2 ;
parameter  A__B__3 = 11.61 ;
parameter  A__C__3 = 11.61 ;
parameter  A__A__3 = 5 ;
parameter BV85 = 2.125 ;
parameter  A__B__4 = 10.35 ;
parameter  A__C__4 = 10.35 ;
parameter  A__A__4 = 5 ;
parameter BV90 = 2.25 ;
parameter  A__B__5 = 9.15 ;
parameter  A__C__5 = 9.15 ;
parameter  A__A__5 = 5 ;
parameter BV95 = 2.375 ;
parameter  A__B__6 = 8.52 ;
parameter  A__C__6 = 8.52 ;
parameter  A__A__6 = 5 ;
parameter BV100 = 2.5 ;
parameter  A__B__7 = 7.85 ;
parameter  A__C__7 = 7.85 ;
parameter  A__A__7 = 5 ;
parameter BV105 = 2.625 ;
parameter  A__B__8 = 7.25 ;
parameter  A__C__8 = 7.25 ;
parameter  A__A__8 = 5 ;
parameter BV110 = 2.75 ;
parameter  A__B__9 = 6.77 ;
parameter  A__C__9 = 6.77 ;
parameter  A__A__9 = 5 ;
parameter BV115 = 2.875 ;
parameter  A__B__10 = 6.37 ;
parameter  A__C__10 = 6.37 ;
parameter  A__A__10 = 5 ;
parameter BV120 = 3 ;
parameter  A__B__11 = 5.94;
parameter  A__C__11 = 5.94 ;
parameter  A__A__11 = 5 ;
parameter BV125 = 3.125 ;
parameter  A__B__12 = 5.64 ;
parameter  A__C__12 = 5.64 ;
parameter  A__A__12 = 5 ;

	__spl	#(bias_voltage,
		BV70, A__B__1, A__C__1, A__A__1,
		BV75, A__B__2, A__C__2, A__A__2,
		BV80, A__B__3, A__C__3, A__A__3,
		BV85, A__B__4, A__C__4, A__A__4,
		BV90, A__B__5, A__C__5, A__A__5,
		BV95, A__B__6, A__C__6, A__A__6,
		BV100, A__B__7, A__C__7, A__A__7,
		BV105, A__B__8, A__C__8, A__A__8,
		BV110, A__B__9, A__C__9, A__A__9,
		BV115, A__B__10, A__C__10, A__A__10,
		BV120, A__B__11, A__C__11, A__A__11,
		BV125, A__B__12, A__C__12, A__A__12)	spl_0(a, b, c);
endmodule
