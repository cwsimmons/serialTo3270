`timescale 1ns / 1ps

/*
 * UART Transmitter
 */

module uartTransmitter (
  input clk,
  input reset,
  input dataAvailable,
  input [7:0] data,
  output reg ren,
  output serialOut
);
  
  parameter CLOCKS_PER_BIT = 868;
  
  reg state;
  reg [15:0] timer;
  reg [3:0] bitCount;
  reg [7:0] outbox;
  
  wire parity;
  wire [11:0] frame;
  
  assign parity = ^outbox;
  assign frame = {2'b11, parity, outbox, 1'b0};
  assign serialOut = (state) ? frame[bitCount] : 1'b1;
  
  always @(posedge clk)
  begin
    if (reset)
    begin
      
      state <= 0;
      ren <= 0;
      
    end
    else if (!state)
    begin
      
      if (dataAvailable)
      begin
        state <= 1;
        timer <= 0;
        bitCount <= 0;
        outbox <= data;
        ren <= 1;
      end
      
    end
    else
    begin
      
      ren <= 0;
      
      if (timer == CLOCKS_PER_BIT)
      begin
        
        timer <= 0;
        if (bitCount == 11)
          state <= 0;
        else
          bitCount <= bitCount + 1;
        
      end
      else
        timer <= timer + 1;
      
    end
  end
  
endmodule