module contouring #(parameter WIDTH = 128)(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire pixel, //gris
    output reg valid_o,
	output reg pixel_o);
	
	reg [WIDTH-1:0] line; //fila/pixeles anteriores
	reg [9:0] x;//columna
    reg up_prev;//arriba-izq

    wire up = line[WIDTH-1];
    wire left = (x == 10'd0) ? 1'b0 : line[0];
    wire ul = (x == 10'd0) ? 1'b0 : up_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_o <= 1'b0;
            start_o <= 1'b0;
            pixel_o <= 1'b0;
            line <= {WIDTH{1'b0}};
            x <= 10'd0;
            up_prev <= 1'b0;
        end else begin
            valid_o <= valid;
            if (valid) begin
                pixel_o <= pixel & left & up & ul;//solo si los vecinos están activos
                line <= {line[WIDTH-2:0], pixel};
                up_prev <= up;
                x <= (x == WIDTH-1) ? 10'd0 : x + 10'd1;
            end
        end
    end
endmodule
