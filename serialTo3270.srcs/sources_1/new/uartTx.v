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
  parameter PARITY_ENABLED = 0;
  parameter PARITY_IS_ODD = 0;
  parameter STOP_BITS = 1;
  
  reg [1:0] state;
  reg [15:0] timer;
  reg [3:0] bitCount;
  reg [7:0] outbox;
  
  wire parity;
  wire [9:0] frame;
  
  assign parity = (PARITY_IS_ODD == 1) ? ~^outbox : ^outbox;
  assign frame = {parity, outbox, 1'b0};
  assign serialOut = (state == 1) ? frame[bitCount] : 1'b1;
  
  always @(posedge clk)
  begin
    ren <= 0;
    
    if (reset)
    begin
      
      state <= 0;
      
    end
    else if (state == 0)
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
    else if (state == 1)
    begin
      
      if (timer == CLOCKS_PER_BIT)
      begin
        
        timer <= 0;
        if (bitCount == 8 + ((PARITY_ENABLED == 1) ? 1 : 0))
        begin
          state <= 2;
          bitCount <= 0;
        end
        else
          bitCount <= bitCount + 1;
        
      end
      else
        timer <= timer + 1;
      
    end
    else if (state == 2)
    begin
    
      if (timer == CLOCKS_PER_BIT)
      begin
        
        timer <= 0;
        if (bitCount == STOP_BITS - 1)
          state <= 0;
        else
          bitCount <= bitCount + 1;
        
      end
      else
        timer <= timer + 1;
    
    end
  end
  
endmodule