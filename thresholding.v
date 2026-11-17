module thresholding #(parameter BRIGHT = 1) //BRIGHT = 1, los más claros en escala de gris se vuelven blancos, de lo contrario (BRIGHT = 0) negros
	(input wire clk,
    input wire rst,
    input wire valid,
	input wire [7:0] gray,
    output reg valid_o,
	 output reg pixel); //255->1 ("blanco" o "negro")

	localparam th = 8'd127; //umbral: 127/255
	
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
