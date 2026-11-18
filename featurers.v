//Grayscale-->thresholding:	  Iriun Cam->py-uart->fpga
//----------#--------
//--------#####------
//-------#######-----
//------*###+####----
//-------########----
//--------#####------
//----------#--------

//Perímetro Suma de #s, Área: Suma y conteo de #---------#
//Cápsula/Forma: máx, mín ->centroide 
//* tallo, característica para detectar

module features #(parameter WIDTH = 128, parameter HEIGHT = 128)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire valid,
    input wire pixel, //ya erosionados
	
    output reg done,
    output reg [13:0] area, //16385 px máx-> 14 bits
    output reg [15:0] perimeter,
    output reg [7:0] w, //8 bits de ancho/largo máximos
	output reg [7:0] h,
	output reg [7:0] cx,
	output reg [7:0] cx);
	
    reg [WIDTH-1:0] line;
	reg [9:0] x, y;
	reg [13:0] a;
	reg [15:0] p;
	reg [7:0] xmin, xmax, ymin, ymax;
	reg [19:0] sum_x, sum_y;
    reg last; //fin

	//vecinos
    wire up = line[WIDTH-1];
    wire left = (x == 10'd0) ? 1'b0 : line[0];

	//perímetro
    wire [16:0] p_add =
        pixel ? (17'd4
                - (left ? 17'd2 : 17'd0)
                - (up   ? 17'd2 : 17'd0))
              : 17'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
            area <= 0;
            perimeter <= 0;
            cx <= 0;
            cy <= 0;
            w <= 0;
            h <= 0;
            line <= 0;
            x <= 0;
            y <= 0;
            a <= 0;
            p <= 0;
            sum_x <= 0;
            sum_y <= 0;
            xmin <= 7'd0;
            xmax <= 0;
            ymin <= 7'd0;
            ymax <= 0;
            last <= 0;
        end else begin
            done <= 1'b0;
            //imagen nueva
            if (start) begin
                line <= 0;
                x <= 0;
                y <= 0;
                a <= 0;
                p <= 0;
                sum_x <= 0;
                sum_y <= 0;
                xmin <= 7'd0;
                xmax <= 0;
                ymin <= 7'd0;
                ymax <= 0;
                last <= 0;
            end else if (last) begin
                area <= a;
                perimeter <= p;
                if (a != 0) begin
                    cx <= sum_x / a;
                    cy <= sum_y / a;
                    w <= xmax - xmin + 1'b1;
                    h <= ymax - ymin + 1'b1;
                end else begin
                    cx <= 0;
                    cy <= 0;
                    w <= 0;
                    h <= 0;
                end
                done <= 1'b1;
                last <= 1'b0;
            end else if (valid) begin
                line <= {line[WIDTH-2:0], pixel};
				if (pixel) begin //Área, centroide, min, max
                    a <= a + 1'b1;
                    sum_x <= sum_x + x;
                    sum_y <= sum_y + y;
                    if (x < xmin) xmin <= x[6:0];
                    if (x > xmax) xmax <= x[6:0];
                    if (y < ymin) ymin <= y[6:0];
                    if (y > ymax) ymax <= y[6:0];
                end
                p <= p + p_add;
                if (x == WIDTH-1) begin
                    x <= 0;
                    if (y == HEIGHT-1) begin
                        y <= 0;
                        last <= 1'b1;
                    end else begin
                        y <= y + 1'b1;
                    end
                end else begin
                    x <= x + 1'b1;
                end

            end
        end
    end
endmodule
