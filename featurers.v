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

module features #(parameter WIDTH = 640, parameter HEIGHT = 480)(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire start,
    input wire pixel,
    output reg done,
    output reg [18:0] area,
    output reg [19:0] perimeter,
    output reg [9:0] w,
    output reg [9:0] h);
	
    reg [WIDTH-1:0] line;
    reg [9:0] x, y;
    reg [18:0] a;
    reg [19:0] p;
    reg [9:0] xmin, xmax, ymin, ymax;
    reg seen;
    reg last;

    wire up = line[WIDTH-1];
    wire left = (x == 10'd0) ? 1'b0 : line[0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;  last <= 1'b0;
            area <= 19'd0; perimeter <= 20'd0; w <= 10'd0; h <= 10'd0;
            line <= {WIDTH{1'b0}};
            x <= 10'd0; y <= 10'd0; a <= 19'd0; p <= 20'd0; seen <= 1'b0;
            xmin <= 10'h3FF; xmax <= 10'd0; ymin <= 10'h3FF; ymax <= 10'd0;
        end else begin
            done <= 1'b0;
            last <= 1'b0;

            if (start) begin
                line <= {WIDTH{1'b0}};
                x <= 10'd0; y <= 10'd0; a <= 19'd0; p <= 20'd0; seen <= 1'b0;
                xmin <= 10'h3FF; xmax <= 10'd0; ymin <= 10'h3FF; ymax <= 10'd0;
            end else if (valid) begin
                line <= {line[WIDTH-2:0], pixel};
																					
                p <= p + (pixel ^ left) + (pixel ^ up);

                if (pixel) begin
                    a <= a + 19'd1;
                    seen <= 1'b1;
                    if (x < xmin) xmin <= x;
                    if (x > xmax) xmax <= x;
                    if (y < ymin) ymin <= y;
                    if (y > ymax) ymax <= y;
                end

                if (x == WIDTH-1) begin
                    x <= 10'd0;
                    if (y == HEIGHT-1) begin
                        y <= 10'd0;
                        last <= 1'b1;
                    end else begin
                        y <= y + 10'd1;
                    end
                end else begin
                    x <= x + 10'd1;
                end
            end
																					
            if (last) begin
                area <= a;
                perimeter <= p;
                w <= seen ? (xmax - xmin + 10'd1) : 10'd0;
                h <= seen ? (ymax - ymin + 10'd1) : 10'd0;
                done <= 1'b1;
            end
        end
    end
endmodule
