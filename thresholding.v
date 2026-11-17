module thresholding #(parameter BRIGHT = 1)(
    input wire clk,
    input wire rst,
    input wire valid,
	input wire [7:0] gray,
	input wire [7:0] th,
    output reg valid_o,
	output reg pixel); //"blanco" o "negro"
	
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_o <= 1'b0;
            pixel <= 1'b0;
        end else begin
            valid_o <= valid;
            if (valid) pixel <= BRIGHT ? (gray > th) : (gray < th);
        end
    end
endmodule
