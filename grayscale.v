module grayscale(
    input wire clk,
    input wire rst,
    input wire valid,
	input wire [7:0] R,
	input wire [7:0] G,
	input wire [7:0] B,
    output reg valid_o,
	output reg [7:0] gray); //0-255

	//4*255=1020->10bits
	wire [9:0] sum = {2'b00, R} + {1'b0, G, 1'b0} + {2'b00, B};//R+G<<1+B=R+2G+B

    always @(posedge clk or posedge rst) begin
        if (rst) begin	//rst
            valid_o <= 1'b0;
			gray <= 8'b0;
        end else begin
            valid_o <= valid;
			if (valid) gray <= sum[9:2];//gray=(R+2G+B)>>2=(R+2G+B)/4
        end
    end
endmodule
