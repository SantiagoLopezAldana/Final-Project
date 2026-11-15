module classify#(
    parameter AREA_MIN = 1500,
    parameter AREA_MAX = 6000,
    parameter PERIM_MIN = 150,
    parameter PERIM_MAX = 500,
    parameter AR_MIN = 20,
    parameter AR_MAX = 40
)(
    input wire clk,
    input wire rst,
    input wire done,
    input wire [18:0] area,
    input wire [19:0] perimeter,
    input wire [9:0] w,
    input wire [9:0] h,
    output reg result_valid,
    output reg is_bean);
    wire [9:0] lng = (w >= h) ? w : h;
    wire [9:0] sht = (w >= h) ? h : w;
    wire [31:0] l16 = {18'd0, lng, 4'd0};
    wire [31:0] lo = AR_MIN * sht;
    wire [31:0] hi = AR_MAX * sht;

    wire ok_area = (area >= AREA_MIN) && (area <= AREA_MAX);
    wire ok_per = (perimeter >= PERIM_MIN) && (perimeter <= PERIM_MAX);
    wire ok_ar = (sht != 10'd0) && (l16 >= lo) && (l16 <= hi);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_valid <= 1'b0;
            is_bean      <= 1'b0;
        end else begin
            result_valid <= done;
            if (done) is_bean <= ok_area & ok_per & ok_ar;
        end
    end
endmodule
