module thresholding (
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [7:0] gray,
    output reg valid_o,
    output reg pixel
);

    localparam th = 8'd127;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_o <= 1'b0;
            pixel   <= 1'b0;
        end else begin
            valid_o <= valid;
            if (valid) begin
                if (gray < th) pixel <= 1'b1; // Frijol oscuro -> 1
                else           pixel <= 1'b0; // Fondo claro   -> 0
            end
        end
    end
endmodule

