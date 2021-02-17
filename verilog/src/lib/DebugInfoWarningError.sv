// written 2021-02-16 by mza
// last updated 2021-02-17 by mza

// with help from http://ionipti.blogspot.com/2012/08/systemverilog-variable-argument-display.html

// usage:
//import DebugInfoWarningError::*;
//`info("%d:%d", a, b);
//`error("too many errors");

package DebugInfoWarningError;
//	function void display_debug (string message);
	task display_debug (string message);
		$display("%t   DEBUG: %s", $time, message);
	endtask
//	endfunction
	task display_info (string message);
		$display("%t %s", $time, message);
	endtask
	task display_warning (string message);
		$display("%t WARNING: %s", $time, message);
	endtask
	task display_error (string message);
		$display("%t   ERROR: %s", $time, message);
		#1;
		$finish;
	endtask
	`define DELIM
	`define debug(p0, p1=ELIM, p2=ELIM, p3=ELIM, p4=ELIM, p5=ELIM) \
		`ifdef D``p1 \
			display_debug($psprintf(p0)); \
		`else \
		`ifdef D``p2 \
			display_debug($psprintf(p0, p1)); \
		`else \
		`ifdef D``p3 \
			display_debug($psprintf(p0, p1, p2)); \
		`else \
		`ifdef D``p4 \
			display_debug($psprintf(p0, p1, p2, p3)); \
		`else \
		`ifdef D``p5 \
			display_debug($psprintf(p0, p1, p2, p3, p4)); \
		`else \
			display_debug($psprintf(p0, p1, p2, p3, p4, p5)); \
		`endif \
		`endif \
		`endif \
		`endif \
		`endif
	`define info(p0, p1=ELIM, p2=ELIM, p3=ELIM, p4=ELIM, p5=ELIM) \
		`ifdef D``p1 \
			display_info($psprintf(p0)); \
		`else \
		`ifdef D``p2 \
			display_info($psprintf(p0, p1)); \
		`else \
		`ifdef D``p3 \
			display_info($psprintf(p0, p1, p2)); \
		`else \
		`ifdef D``p4 \
			display_info($psprintf(p0, p1, p2, p3)); \
		`else \
		`ifdef D``p5 \
			display_info($psprintf(p0, p1, p2, p3, p4)); \
		`else \
			display_info($psprintf(p0, p1, p2, p3, p4, p5)); \
		`endif \
		`endif \
		`endif \
		`endif \
		`endif
	`define warning(p0, p1=ELIM, p2=ELIM, p3=ELIM, p4=ELIM, p5=ELIM) \
		`ifdef D``p1 \
			display_warning($psprintf(p0)); \
		`else \
		`ifdef D``p2 \
			display_warning($psprintf(p0, p1)); \
		`else \
		`ifdef D``p3 \
			display_warning($psprintf(p0, p1, p2)); \
		`else \
		`ifdef D``p4 \
			display_warning($psprintf(p0, p1, p2, p3)); \
		`else \
		`ifdef D``p5 \
			display_warning($psprintf(p0, p1, p2, p3, p4)); \
		`else \
			display_warning($psprintf(p0, p1, p2, p3, p4, p5)); \
		`endif \
		`endif \
		`endif \
		`endif \
		`endif
	`define error(p0, p1=ELIM, p2=ELIM, p3=ELIM, p4=ELIM, p5=ELIM) \
		`ifdef D``p1 \
			display_error($psprintf(p0)); \
		`else \
		`ifdef D``p2 \
			display_error($psprintf(p0, p1)); \
		`else \
		`ifdef D``p3 \
			display_error($psprintf(p0, p1, p2)); \
		`else \
		`ifdef D``p4 \
			display_error($psprintf(p0, p1, p2, p3)); \
		`else \
		`ifdef D``p5 \
			display_error($psprintf(p0, p1, p2, p3, p4)); \
		`else \
			display_error($psprintf(p0, p1, p2, p3, p4, p5)); \
		`endif \
		`endif \
		`endif \
		`endif \
		`endif
endpackage

// notes:
//
// $psprintf("%d:%d", a, b);
//
// logfile = $fopen("logfile.log", "w");
// $fdisplay(logfile, "%t", $time);
// $fclose(logfile);
//
// $fdisplay(1, "%t", $time); // STDOUT
// $fdisplay(2, "%t", $time); // STDERR
// $fdisplay(STDERR, "%t", $time);

//package firsttry;
//	string message;
//	task debug (string message);
//		$display("%t   DEBUG: %s", $time, message);
//	endtask
//	task info (string message);
//		$display("%t %s", $time, message);
//	endtask
//	task warning (string message);
//		$display("%t WARNING: %s", $time, message);
//	endtask
//	task error (string message);
//		$display("%t   ERROR: %s", $time, message);
//		$finish;
//	endtask
//endpackage

