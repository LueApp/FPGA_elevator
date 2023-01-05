`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/03 17:14:08
// Design Name: 
// Module Name: ajxd
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


module ajxd(
    input [3:0]btn_in,
    input btn_clk,
    output [3:0]btn_out
    );  
    reg  [3:0] btn0=0;//������btn0�Ĵ���
    reg  [3:0] btn1=0;//������btn1�Ĵ���
    reg  [3:0] btn2=0;//������btn2�Ĵ���
    always@(posedge btn_clk)
    begin
        btn0<=btn_in;
        btn1<=btn0;
        btn2<=btn1;
    end
    assign btn_out=(btn2&btn1&btn0)|(~btn2&btn1&btn0);
endmodule
