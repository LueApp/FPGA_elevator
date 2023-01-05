`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/03 13:43:42
// Design Name: 
// Module Name: decoder_7seg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoder_7seg (    
    input [4:0] cnt,    //计时
    input [1:0] floor,  //楼层
    output reg [7:0] seg,
    output reg [5:0] dig,
    input clkin
    );
    //分频用以不同数码管显示
    reg clk=0;
    integer    qout=0;
    always@(posedge clkin)begin    
        if(qout==24999) //1ms
        begin
            qout<=0;
            clk<=~clk;
        end
        else qout<=qout+1;
    end
    //状态机实现数码管切换
    integer state=0,showdata;
    always@(posedge clk)begin
        //楼层显示
        if(state==0)begin
            state<=1;
            dig=6'b111110;
            showdata=floor;
            seg[0]=0;
        end
        //计时个位
        else if(state==1)begin
            state<=2;
            dig=6'b011111;
            showdata=cnt/10;
            seg[0]=1;   //小数点位单独判断
        end
        //计时十分位
        else if(state==2)begin
            state<=0;
            dig=6'b101111;
            showdata=cnt%10;
            seg[0]=0;
        end
    end
    //数字位判断
    always@(showdata)
        case(showdata)
            4'b0000: seg[7:1] = 7'b1111110;
            4'b0001: seg[7:1] = 7'b0110000;
            4'b0010: seg[7:1] = 7'b1101101;
            4'b0011: seg[7:1] = 7'b1111001;
            4'b0100: seg[7:1] = 7'b0110011;
            4'b0101: seg[7:1] = 7'b1011011;
            4'b0110: seg[7:1] = 7'b0011111;
            4'b0111: seg[7:1] = 7'b1110000;
            4'b1000: seg[7:1] = 7'b1111111;
            4'b1001: seg[7:1] = 7'b1110011;
            default: seg[7:1] = 7'b0000000;
        endcase
endmodule