`timescale 1ns / 1ps


module testbench();

    reg clk;
    reg reset;
    wire uartIn;
    wire uartOut;
    reg sclk12;
    wire serialIn;
    wire serialOut;
    wire serialOutComplement;
    wire serialOutDelayed;
    wire TxActive;

    /*  CLOCKS  */

    always #5 clk = ~clk;
    always #18 sclk12 = ~sclk12;

    /*  UUT  */

    serialTo3270 #(6, 1, 0, 2, 11) converter(
        .clk                    (clk),
        .reset                  (reset),
        .uartIn                 (uartIn),
        .uartOut                (uartOut),
        .sclk12                 (sclk12),
        .serialIn               (serialIn),
        .serialOut              (serialOut),
        .serialOutComplement    (serialOutComplement),
        .serialOutDelayed       (serialOutDelayed),
        .TxActive               (TxActive)
    );

    /*  Mock Terminal  */

    terminal MockTerminal(
        .clk                    (clk),
        .reset                  (reset),
        .sclk12                 (sclk12),
        .serialIn               (serialOut),
        .serialOut              (serialIn)
    );


    /*  Test UART */

    reg TxWen;
    reg [7:0] TxWriteData;
    wire TxRen;
    wire [7:0] TxReadData;
    wire TxDataAvailable;

    fifo #(8, 4) TxUartFifo(
        .clk                    (clk),
        .reset                  (reset),
        .mode                   (1'b1),
        .wen                    (TxWen),
        .ren                    (TxRen),
        .write                  (TxWriteData),
        .read                   (TxReadData),
        .state                  (TxDataAvailable),
        .occupancy              ()
    );

    uartTransmitter #(6, 1, 0, 2) TxUart(
        .clk                    (clk),
        .reset                  (reset),
        .dataAvailable          (TxDataAvailable),
        .data                   (TxReadData),
        .ren                    (TxRen),
        .serialOut              (uartIn)
    );

    wire [7:0] uartResponse;

    uartReceiver #(6) RxUart(
        .clk                    (clk),
        .reset                  (reset),
        .serialIn               (uartOut),
        .data                   (uartResponse),
        .dataAvailable          ()
    );

    task writeToUart;
    input [7:0] data;
    begin
        @(posedge clk)
        TxWriteData <= data;
        TxWen <= 1;
        @(posedge clk)
        TxWen <= 0;
    end
    endtask

    /* Behaviour */

    initial
    begin
        clk = 0;
        sclk12 = 0;
        reset = 1;
        TxWen = 0;
        TxWriteData = 0;

        #10 reset = 0;

        #10 writeToUart(8'hA6);
        #10 writeToUart(8'h03);
        #10 writeToUart(8'hD2);
        #10 writeToUart(8'h02);
        #10 writeToUart(8'hC0);
        #10 writeToUart(8'h90);
        #10 writeToUart(8'h01);
        #10 writeToUart(8'hC0);

        #25000;
    end


endmodule
