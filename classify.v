module classify#(
    parameter AREA_MIN = 1500,
    parameter AREA_MAX = 6000,
    parameter PERIM_MIN = 150,
    parameter PERIM_MAX = 500,
    parameter AR_MIN = 20,
    parameter AR_MAX = 40)(
    input wire clk,
    input wire rst,
    input wire done,
    input wire [14:0] area,
    input wire [16:0] perimeter,
    input wire [7:0] w,
    input wire [7:0] h,
    input wire [7:0] cx,
    input wire [7:0] cy,
    output reg result_valid,
    output reg is_bean);
    
    wire [7:0] lng = (w >= h) ? w : h;
    wire [7:0] sht = (w >= h) ? h : w;
    wire [15:0] l16 = {4'd0, lng, 4'd0};
    wire [15:0] lo = AR_MIN * sht;
    wire [15:0] hi = AR_MAX * sht;
    //FALTA EL CENTROIDE
    
    wire ok_area =
        (area >= AREA_MIN) &&
        (area <= AREA_MAX);
    wire ok_per =
        (perimeter >= PERIM_MIN) &&
        (perimeter <= PERIM_MAX);
    wire ok_ar =
        (sht != 0) &&
        (l16 >= lo) &&
        (l16 <= hi);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_valid <= 1'b0;
            is_bean <= 1'b0;
        end else begin
            result_valid <= done;
            if (done)
                is_bean <= ok_area && ok_per && ok_ar;
        end
    end
endmodule
