/*
 * UART Receiver
 */

module uartReceiver (
  input clk,
  input reset,
  input serialIn,
  output reg [7:0] data,
  output reg dataAvailable
);

  parameter CLOCKS_PER_BIT = 868;
  
  reg [2:0] history;
  wire filtered;
  reg prevFiltered;
  
  assign filtered = (history[2] && history[1]) ||
                    (history[2] && history[0]) ||
                    (history[1] && history[0]);
  
  always @(posedge clk)
  begin
    history <= {history[1:0], serialIn};
    prevFiltered <= filtered;
  end
  
  reg state;
  reg [7:0] shiftIn;
  reg [3:0] bitCount;
  reg [15:0] timer;
  
  always @(posedge clk)
  begin
    
    dataAvailable <= 0;
    
    if (reset)
    begin
      
      state <= 0;
      
    end
    else if (state == 0)
    begin
      
      if (prevFiltered && !filtered)
      begin
        state <= 1;
        timer <= 0;
        bitCount <= 0;
      end
      
    end
    else if (state == 1)
    begin
      
      if ((timer == CLOCKS_PER_BIT ) || (prevFiltered != filtered))
        timer <= 0;
      else
        timer <= timer + 1;
        
      if (timer == CLOCKS_PER_BIT/2)
      begin
        
        if (bitCount == 9)
        begin
          
          state <= 0;
          
          if (^shiftIn == filtered)
          begin
            
            dataAvailable <= 1;
            data <= shiftIn;
            
          end
          
        end
        else
        begin
          
          shiftIn <= {filtered, shiftIn[7:1]};
          bitCount <= bitCount + 1;
          
        end
        
      end
      
    end
    
  end
  
endmodule