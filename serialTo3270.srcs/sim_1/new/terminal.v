`timescale 1ns / 1ps


module terminal(
    input clk,
    input reset,
    input sclk12,
    input serialIn,
    output serialOut
);

    reg sclk;
    reg [1:0] divider;
    
    always @(posedge sclk12 or posedge reset)
    begin
       if (reset)
       begin
           sclk <= 0;
           divider <= 0;
       end
       else if (divider == 2)
       begin
           sclk <= ~sclk;
           divider <= 0;
       end
       else
           divider <= divider + 1;
    
    end

    wire txAvailable;
    wire [9:0] txData;
    wire txAck;
    wire [11:0] rxData;
    wire rxAvailable;
    wire rxActive;
    wire txActive;

    transmitter TxCoax(
        .clk                    (clk),
        .reset                  (reset),
        .sclk                   (sclk),
        .dataAvailable          (!rxActive && txAvailable),
        .data                   (txData),
        .ren                    (txAck),
        .serialOut              (serialOut),
        .serialOutComplement    (),
        .serialOutDelayed       (),
        .active                 (txActive)
    );

    receiver RxCoax(
        .clk                    (clk),
        .reset                  (reset),
        .enable                 (!txActive),
        .serialIn               (serialIn),
        .active                 (rxActive),
        .rxWord                 (rxData),
        .wordAvailable          (rxAvailable)
    );


    fifo #(10,4) Fifo(
        .clk                    (clk),
        .reset                  (reset),
        .mode                   (1'b1),
        .wen                    (rxAvailable),
        .ren                    (txAck),
        .write                  (rxData[10:1]),
        .read                   (txData),
        .state                  (txAvailable),
        .occupancy              ()
    );







endmodule
