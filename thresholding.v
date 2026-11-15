module thresholding #(parameter bits = 8, parameter BRIGHT = 1)(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire start,
    input wire [bits-1:0] gray,
    input wire [bits-1:0] th,
    output reg valid_o,
    output reg start_o,
    output reg pixel);
	
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_o <= 1'b0;
            start_o <= 1'b0;
            pixel <= 1'b0;
        end else begin
            valid_o <= valid;
            start_o <= start;
            if (valid) pixel <= BRIGHT ? (gray > th) : (gray < th);
        end
    end
endmodule
