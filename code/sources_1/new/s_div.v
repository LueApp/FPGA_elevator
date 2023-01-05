`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/03 12:56:34
// Design Name: 
// Module Name: s_div
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

module s_div (clkin,clkout,clkout2,clkout3);
    input	clkin;
    output    reg  clkout=0,clkout2=0,clkout3=0;//用reg后面always中需要改变数值。
    integer    qout=0,qout2=0,qout3=0;
    //用行为描述实现
    always@(posedge clkin)
    begin    
        if(qout==2499999) //100ms
        begin
            qout<=0;
            clkout<=~clkout;
        end
        else    qout<=qout+1;
        if(qout2==499999) //20ms
        begin
            qout2<=0;
            clkout2<=~clkout2;
        end
        else    qout2<=qout2+1;
        if(qout3==49999) //2ms
        begin
            qout3<=0;
            clkout3<=~clkout3;
        end
        else    qout3<=qout3+1;
    end
endmodule
