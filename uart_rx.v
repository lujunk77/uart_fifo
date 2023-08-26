//基于urat协议的串口环回实验
//波特率为9600
module uart_rx (
	clk,    // Clock
	rst_n,  // Asynchronous reset active low
	rx_uart,
	dout,
	dout_vld
);
	parameter BPS      = 5208 ;//9600波特率传递一个数据的clk周期个数\
	parameter BPS_half = BPS/2;
	input				clk       ;//50Mhz 
	input				rst_n     ;
	input				rx_uart   ;//串口输入信号
	output	 reg   [7:0]dout 	  ;//串口输出信号
	output   reg 		dout_vld  ;//接收到数据的有效指示信号

// 首先对输入信号进行打拍
	reg rx_uart_f_0;
	reg rx_uart_f_1;
	reg rx_uart_f_2;
	reg rx_uart_f_3;
	wire rx_en;
	always @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			rx_uart_f_0 <= 0;
			rx_uart_f_1 <= 0;
			rx_uart_f_2 <= 0;
			rx_uart_f_3 <= 0;
		end else begin
			rx_uart_f_0 <= rx_uart    ;
			rx_uart_f_1 <= rx_uart_f_0;
			rx_uart_f_2 <= rx_uart_f_1;
			rx_uart_f_3 <= rx_uart_f_2;
		end
	end

	assign rx_en = rx_uart_f_1 && (~rx_uart_f_2);//检测下降沿（检测到开始位）
/////////****end*********///////


////////****9600波特率计数器****//////
	reg  [13:0]cnt_bps;      //完整一位的时间
	wire end_bps_half; //BPS一半的时间
	wire add_cnt_bps_rx;
	wire end_cnt_bps_rx;
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			cnt_bps<= 0;
		end 
		else if(add_cnt_bps_rx) begin
			if(end_cnt_bps_rx)
				cnt_bps <= 0;
			else begin
				cnt_bps <= cnt_bps + 1'b1;
			end
		end
	end

	assign add_cnt_bps_rx = bps_flag;
	assign end_cnt_bps_rx = add_cnt_bps_rx && (cnt_bps ==BPS -1);
	assign end_bps_half= add_cnt_bps_rx && (cnt_bps ==BPS_half -1);
//////********end********//

/////******捕捉下降沿的信号***///
reg bps_flag;
always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 bps_flag<= 0;
	end 
	else if(rx_en)begin
		 bps_flag<= 1;
	end
	else if(end_flag)begin
		 bps_flag<=0;
	end
end




//********end**********///

/////*******对数据传输位数的计数*******////

reg [3:0] data_num;
wire add_flag;
wire end_flag;
always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		data_num<= 0;
	end 
	else if (add_flag)begin
		 if(end_flag) begin
		 	data_num<=0;
		 end
		 else
		 	data_num<=data_num+1'b1;
	end
end
assign add_flag = bps_flag && end_cnt_bps_rx;
assign end_flag = add_flag && data_num==9-1;
//////******end********//


/////*******数据输出*******////

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		dout<= 0;
	end 
	else if(end_bps_half&&(data_num!=0)) begin
		dout<= {rx_uart_f_3,{dout[7:1]}};
	end
	else 
		dout<=dout;
end


//////******end********//

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		 dout_vld<= 0;
	end 
	else if(end_cnt_bps_rx&&(data_num==4'd8)) begin
		 dout_vld<= 1;
	end
	else dout_vld <=0;
end


/////******数据输出使能********//

endmodule