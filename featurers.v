//Grayscale-->thresholding:	  Iriun Cam->py-uart->fpga
//----------#--------
//--------#---#------
//-------#-----#-----
//------*---+---#----
//-------#------#----
//--------#...#------
//----------#--------

//Perímetro Suma de #s, Área: Suma y conteo de #---------#
//Cápsula/Forma: máx, mín ->centroide 
//* tallo, característica para detectar

module features #(parameter WIDTH = 1000, parameter HEIGHT = 500)(
	input wire clk,
	input wire rst,
	input wire valid,
	input wire tick,
	input wire pix,
	output reg done,
	output reg [19:0] area,
	output reg [19:0] perimeter,
	output reg [9:0] width,
	output reg [9:0] height);
	
	reg [9:0] x,y, xmin, xmax, ymin, ymax;
	reg [19:0]A, P;
	
	always@(posedge clk or posedge rst) begin
		if(rst) begin
			area <= 19'd0;
			perimeter <= 19'd0;
		end
	end
endmodule