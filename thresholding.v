module thresholding 
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
			if (valid) begin
				if (gray > th) pixel <= 1; //si mayor al umbral blanco
				else pixel <= 0; //si es menor es negro
			end
        end
    end
endmodule
