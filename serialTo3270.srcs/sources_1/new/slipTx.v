/*
 * SLIP Transmitter
 */

`define FRAME_END      8'hC0
`define FRAME_ESC      8'hDB
`define FRAME_ESC_END  8'hDC
`define FRAME_ESC_ESC  8'hDD

module slipTx (
    input clk,
    input reset,

    input dataOutAcknowledge,

    input [7:0] dataIn,
    input dataInAvailable,
    output reg dataInAck,

    input endIn,

    output reg [7:0] dataOut,
    output reg dataOutAvailable

);

    reg escaped;

    always @(posedge clk)
    begin
        dataInAck <= 0;
        if (reset || dataOutAcknowledge)
        begin
            dataOutAvailable <= 0;
            dataOut <= 0;
            escaped <= 0;
        end
        else if (!dataOutAvailable && dataInAvailable)
        begin
            
            if (endIn)
            begin
                
                dataOut <= `FRAME_END;
                dataOutAvailable <= 1;
                dataInAck <= 1;

            end
            else
            begin
                if (!escaped)
                begin
                    
                    if (dataIn == `FRAME_END || dataIn == `FRAME_ESC)
                    begin
                        
                        escaped <= 1;
                        dataOut <= `FRAME_ESC;
                        dataOutAvailable <= 1;

                    end
                    else
                    begin
                        
                        dataOut <= dataIn;
                        dataOutAvailable <= 1;
                        dataInAck <= 1;

                    end

                end
                else
                begin
                    
                    dataInAck <= 1;

                    if (dataIn == `FRAME_END)
                    begin
                        
                        dataOut <= `FRAME_ESC_END;
                        dataOutAvailable <= 1;

                    end
                    else if (dataIn == `FRAME_ESC)
                    begin
                        
                        dataOut <= `FRAME_ESC_ESC;
                        dataOutAvailable <= 1;

                    end

                end
            end
        end
    end


endmodule