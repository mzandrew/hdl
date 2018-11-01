`timescale 1ns / 1ps
// written 2018-11-01 by mza
// last updated 2018-11-01 by mza

module mza_test025_b2tt (
	output a_p, a_n,
	input clock_p, clock_n,
	input trg_p, trg_n,
	output ack_p, ack_n,
	output rsv_p, rsv_n
);
	wire clock;
	wire trg;
	wire ack = 0;
	wire rsv = 0;
	IBUFDS triggy (.I(trg_p), .IB(trg_n), .O(trg));
	IBUFDS clocky (.I(clock_p), .IB(clock_n), .O(clock));
	OBUFDS acky (.I(ack), .O(ack_p), .OB(ack_n));
	OBUFDS rsvy (.I(rsv), .O(rsv_p), .OB(rsv_n));
	OBUFDS blaster (.I(trg), .O(a_p), .OB(a_n));
endmodule

module mza_test025_b2tt_althea (
	output a_p, a_n,
	input d_p, d_n,
	input c_p, c_n,
	output f_p, f_n,
	output g_p, g_n
);
	mza_test025_b2tt myinstance (
		.a_p(a_p), .a_n(a_n),
		.clock_p(d_p), .clock_n(d_n),
		.trg_p(c_p), .trg_n(c_n),
		.ack_p(f_p), .ack_n(f_n),
		.rsv_p(g_p), .rsv_n(g_n)
	);
endmodule

