`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/03 12:31:02
// Design Name: 
// Module Name: top
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


module top(
    input clkin,    //时钟
    input power,    //启动开关
    input reset,    //复位开关
    input [3:0] col,
    output reg beep,    //蜂鸣器
    output reg [11:0]led,
    output [7:0] seg,
    output [5:0] dig,
    output [3:0] row
    );
    wire clk_100ms,clk_btn,clk_beep;    //100ms时钟，按键扫描时钟，蜂鸣器频率时钟
    wire [3:0]key;
    integer floor1=1,floor2=0,cnt1=0,cnt2=0,EN1=0,EN2=0,datashow=0,rst=0;
    //floor1:1为在1楼 0为不在1楼 cnt1:上楼计数 EN1:1为（等待）上行中
    assign row[3:0]=4'b1110;
    s_div clk(
        .clkin(clkin),
        .clkout(clk_100ms),
        .clkout2(clk_btn),
        .clkout3(clk_beep)
    );
    decoder_7seg dec(
        .cnt(cnt1+cnt2),    //计时显示，由于二者不同时计数即至少有一个为0，因此取加
        .floor(datashow),   //楼层显示
        .seg(seg),
        .dig(dig),
        .clkin(clkin)
    );
    // assign key=col;
    ajxd a(
        .btn_in(col),
        .btn_clk(clk_btn),
        .btn_out(key)
    );
    //“嘀”功能 响0.2s
    always@(posedge clk_beep)begin
        if(cnt1>28||cnt2>28)begin   //周期为4ms，即250Hz
            beep=~beep; //占空比为50%
        end
        else beep=0;
    end
    //以0.1s周期的速度进行计数
    always@(posedge clk_100ms) begin
        rst<=reset;
        //复位
        if(rst^reset)begin  //100ms之间检测到复位键状态不一致，即异或非零
            if(!floor1)begin    //如果不在1楼 那么直接下楼 类似下楼键
                EN2=1;
                EN1=0;
                cnt1=0;
                cnt2=0;
            end
        end
        //未开启
        if(!power) begin
            cnt1=0;
            cnt2=0;
            EN1=0;
            EN2=0;
            datashow=0;
        end
        //开启
        else begin
            //电梯不在2楼，电梯内按下2楼键，等待上行
            if(!floor2&&!key[3])begin
                led[3]=1;
                EN1=1;  //标记有等待上行的按键按下
                cnt1=0;
            end
            //电梯不在1楼，电梯内按下1楼键，等待下行
            if(!floor1&&!key[2])begin
                led[2]=1;
                EN2=1;  //标记有等待下行的按键按下
                cnt2=0;
            end
            //电梯不在2楼，2楼外按下下楼键，等待上行
            if(!floor2&&!key[1])begin
                led[1]=1;
                EN1=1;  //标记有等待上行的按键按下
                cnt1=0;
            end
            //电梯不在1楼，1楼外按下上楼键，等待下行
            if(!floor1&&!key[0])begin
                led[0]=1;
                EN2=1;  //标记有等待下行的按键按下
                cnt2=0;
            end
        end
        //无需等待上行，将上行计数清零，将等待上行显示灯熄灭
        if(!EN1) begin
            cnt1=0;
            led[3]=0;
            led[1]=0;
        end
        //无需等待下行，将下行计数清零，将等待下行显示灯熄灭
        if(!EN2) begin
            cnt2=0;
            led[2]=0;
            led[0]=0;
        end
        //同时有上行和下行的需求
        if(EN1&&EN2)begin
            //在上行
            if(cnt1>cnt2)begin
                cnt1=cnt1+1;
                floor1=0;
            end
            //在下行
            else begin
                cnt2=cnt2+1;
                floor2=0;
            end
        end
        //在上行
        else if(EN1)begin
            cnt1=cnt1+1;
            floor1=0;
        end
        //在下行
        else if(EN2)begin
            cnt2=cnt2+1;
            floor2=0;
        end
        //楼层显示
        if(0<cnt1&&cnt1<20)datashow=1;
        else if(cnt1>=20)datashow=2;
        if(0<cnt2&&cnt2<20)datashow=2;
        else if(cnt2>=20)datashow=1;
        //流水灯功能实现
        if(cnt1+cnt2<6)led[11:7]=0;
        if(cnt1==6)led[7]=1;
        else if(cnt1==12)led[8]=1;
        else if(cnt1==18)led[9]=1;
        else if(cnt1==24)led[10]=1;
        else if(cnt1==30)led[11]=1;
        if(cnt2==6)led[11]=1;
        else if(cnt2==12)led[10]=1;
        else if(cnt2==18)led[9]=1;
        else if(cnt2==24)led[8]=1;
        else if(cnt2==30)led[7]=1;
        //到2楼了
        if(cnt1==30)begin
            EN1=0;
            floor2=1;
            cnt1=0;
        end
        //到1楼了
        if(cnt2==30)begin
            EN2=0;
            floor1=1;
            cnt2=0;
        end
    end
endmodule
