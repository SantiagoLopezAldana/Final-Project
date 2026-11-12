//Imagen con iluminación controlada
module grayscale #(parameter bits_camara = 8)(
	input wire clk,
	input wire rst,
	input wire tick,
	input wire [bits_camara-1:0] r,
	input wire [bits_camara-1:0] g,
	input wire [bits_camara-1:0] b,
	output reg finished,
	output reg tick_out,
	output reg [bits_camara-1:0]  gray);
	
	
	always@(posedge clk or posedge rst) besgin
		if(rst) begin
			finished <= 1'b0;
			tick_out <= 1'b0;
		end
	end
endmodule