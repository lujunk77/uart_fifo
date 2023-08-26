module com_p (
	clk,    // Clock
	rst_n,  // Asynchronous reset active low
	rx_uart,
    tx_uart 
);
parameter    	   BPS	  =	5208;
input               rst_n  ;
input               clk    ;
input               rx_uart;
output              tx_uart;
wire  [7:0]         uart_in     ;
wire                uart_in_vld ;
wire  [7:0]         uart_out    ;
wire                uart_out_vld;
wire                rdy         ;
//串口接收模块
uart_rx#(.BPS(BPS))  uart_rx(
                 .clk     (clk        ),
                 .rst_n   (rst_n      ),
                 .rx_uart     (rx_uart    ),
                 .dout    (uart_in    ),
                 .dout_vld(uart_in_vld)
             );
//fifo模块
data_handle  u_data_handle(
                 .clk     (clk         ),
                 .rst_n   (rst_n       ),
                 .din     (uart_in     ),
                 .din_vld (uart_in_vld ),
                 .dout    (uart_out    ),
                 .dout_vld(uart_out_vld),
                 .rdy     (rdy         )   //避免在tx处理数据时向tx发送信号
                  );         
//串口发送模块             
uart_tx#(.BPS(BPS))  uart_tx(
                 .clk     (clk         ),
                 .rst_n   (rst_n       ),
                 .din     (uart_out    ),
                 .din_vld (uart_out_vld),
                 .rdy     (rdy         ),
                 .uart_tx    (tx_uart     )
             );

endmodule