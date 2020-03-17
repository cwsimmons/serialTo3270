/*
 * SLIP Receiver
 */

`define FRAME_END      8'hC0
`define FRAME_ESC      8'hDB
`define FRAME_ESC_END  8'hDC
`define FRAME_ESC_ESC  8'hDD

module slipRx (
    clk,
    reset,

    dataIn,
    dataInAvailable,

    dataOut,
    dataOutAvailable,

    lengthOut,
    lengthOutAvailable
);

    parameter MAX_LENGTH = 11;

    input clk;
    input reset;

    input [7:0] dataIn;
    input dataInAvailable;

    output reg [7:0] dataOut;
    output reg dataOutAvailable;

    output reg [MAX_LENGTH-1:0] lengthOut;
    output reg lengthOutAvailable;


    reg escaped;
    reg [MAX_LENGTH-1:0] currentLength;

    always @(posedge clk)
    begin

        dataOut <= 0;
        dataOutAvailable <= 0;
        lengthOut <= 0;
        lengthOutAvailable <= 0;

        if (reset)
        begin
            escaped <= 0;
            currentLength <= 0;
        end
        else if (dataInAvailable)
        begin
            if (!escaped)
            begin

                if (dataIn == `FRAME_END)
                begin
                    lengthOut <= currentLength;
                    lengthOutAvailable <= 1;
                    currentLength <= 0;
                end
                else if (dataIn == `FRAME_ESC)
                begin
                    escaped <= 1;
                end
                else
                begin
                    dataOut <= dataIn;
                    dataOutAvailable <= 1;
                    currentLength <= currentLength + 1;
                end

            end
            else
            begin
                
                escaped <= 0;

                if (dataIn == `FRAME_ESC_END)
                begin
                    dataOut <= `FRAME_END;
                    dataOutAvailable <= 1;
                    currentLength <= currentLength + 1;
                end
                else if (dataIn == `FRAME_ESC_ESC)
                begin
                    dataOut <= `FRAME_ESC;
                    dataOutAvailable <= 1;
                    currentLength <= currentLength + 1;
                end

            end
        end

    end
endmodule