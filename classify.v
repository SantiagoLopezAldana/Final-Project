module classify 
	#(parameter AREA_MIN = 100,
	parameter AREA_MAX = 120,
	parameter PERIMETER_MIN = 100,
	parameter PERIMETER_MAX = 120,
	parameter RATIO_MIN = 2,
	parameter RATIO_MAX = 4
	)(
	input wire clk,
	input wire rst,
	input wire done,
	input wire [19:0] area,
	input wire [19:0] perimeter,
	input wire [9:0] width,
	input wire [9:0] height,
	output reg finished,
	output reg is_bean);
	
	always@(posedge clk or posedge rst) begin
		if(rst) begin
			finished <= 1'b0;
			is_bean <= 1'b0;
		end
	end

endmodule