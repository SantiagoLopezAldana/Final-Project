module grayscale #(parameter bits = 8)(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire start,
    input wire [bits-1:0] r,
    input wire [bits-1:0] g,
    input wire [bits-1:0] b,
    output reg valid_o,
    output reg start_o,
    output reg [bits-1:0] gray); //0-255
	
    wire [bits+1:0] sum = {2'b00, r} + {1'b0, g, 1'b0} + {2'b00, b};//R+2G+B

    always @(posedge clk or posedge rst) begin
        if (rst) begin	//rst
            valid_o <= 1'b0;
            start_o <= 1'b0;
            gray <= {bits{1'b0}};
        end else begin
            valid_o <= valid;
            start_o <= start;
            if (valid) gray <= sum[bits+1:2];//gray=(R+2G+B)/4
        end
    end
endmodule
