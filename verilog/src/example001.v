module top (input J1_3, J1_4, output LED5);
  assign LED5 = J1_3 & J1_4;
endmodule

