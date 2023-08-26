module data_handle (
	clk,    // Clock
	rst_n,  // Asynchronous reset active low
	din,
	din_vld,
	dout,
	dout_vld,
	rdy
);
	input		 	clk;
	input		 	rst_n;
	input	   [7:0]din;
	input		 	din_vld;
	input			rdy;
	output  reg[7:0]dout;
	output  reg 	dout_vld;


	wire [7:0] data;
	wire wrreq; //写使能

	assign data  	= din;
	assign wrreq  	= din_vld;
/////fifo IP核
wire empty;
wire full;
wire [7:0]q;
wire [6:0]usedw;//FIFO中储存的字节
my_fifo  my_fifo(
	.clock (clk) ,
	.data  (data) ,
	.rdreq (rdreq) ,
	.wrreq (wrreq) ,
	.empty (empty) ,
	.full  (full) ,
	.q     (q) ,  
	.usedw (usedw) );
//////

	reg rdreq;//读使能 
	always@(*)begin
        if(rd_flag && empty==1'b0 && rdy)
            rdreq = 1'b1;
        else
            rdreq = 1'b0;
    end


    reg rd_flag;//读使能的条件：FIFO储存大于60字节
    always @(posedge clk or negedge rst_n) begin : proc_
    	if(~rst_n) begin
    		rd_flag<= 0;
    	end 
    	else if (rd_flag==1'b0 && usedw>=60)begin
    		rd_flag<= 1'b1;
    	end
    	else if(rd_flag==1'b1  && empty )  
    		rd_flag<= 0;
    end

    ////接收从fifo读出的数据
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			dout<=0;
		end 
		else begin
			dout<=q;
		end
	end

	//输出使能（即为读使能）

	always @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			 dout_vld<= 0;
		end else begin
			 dout_vld<= rdreq;
		end
	end
endmodule