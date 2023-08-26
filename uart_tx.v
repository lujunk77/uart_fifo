module uart_tx (
	clk,    // Clock
	rst_n,  // Asynchronous reset active low
	din,
	din_vld,
	uart_tx,
	rdy
); 
	parameter         BPS 	   = 5208;
	parameter 		  BPS_half = 2604;
	input	clk 		;
	input	rst_n		;
	input	[7:0]din 	;
	input	din_vld 	;//数据接受有效
	output	reg uart_tx ;//输出信号
	output  reg rdy		;//指示信号

/////****接收使能信号****////////		
reg tx_flag;
always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		tx_flag<= 0;
	end 
	else if((tx_flag==1'b0)&& din_vld) begin
		tx_flag<= 1'b1 ;
	end
	else if(tx_flag&&end_cnt_bps_tx&&end_flag) begin
		tx_flag <= 0; 
	end
end

/////****end********/////////




////////****9600波特率计数器****//////
	reg  [13:0]cnt_bps; //完整一位的时间
	wire add_cnt_bps_tx  ;
	wire end_cnt_bps_tx  ;
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			cnt_bps<= 0;
		end 
		else if(add_cnt_bps_tx) begin
			if(end_cnt_bps_tx)
				cnt_bps <= 0;
			else begin
				cnt_bps <= cnt_bps + 1'b1;
			end
		end
		else cnt_bps <=0;
	end

	assign add_cnt_bps_tx = tx_flag;
	assign end_cnt_bps_tx = add_cnt_bps_tx && (cnt_bps ==BPS -1);

//////********end********////




/////**使能时先接收数据****//////


reg [7:0] tx_tmp;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		tx_tmp<= 0;
	end 
	else if((tx_flag ==0)&& din_vld) begin
		tx_tmp<= din;
	end
end


//////********end********//////



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
assign add_flag = tx_flag && end_cnt_bps_tx;
assign end_flag = add_flag && data_num==10-1;
//////******end********//

/////*******发送数据******/////

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		uart_tx<= 0;
	end 
	else if(tx_flag) begin
		if(data_num==0)
			uart_tx<=0; //起始位
		else if(end_flag)
			uart_tx<=1; //结束标志位
		else
			uart_tx<=tx_tmp[data_num-1];
	end
	else uart_tx <=1'b1;
end

/////////******end********//

always  @(*)begin
    if(din_vld || tx_flag)
        rdy = 1'b0;
    else
        rdy = 1'b1;
end

endmodule