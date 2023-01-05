# FPGA_elevator
Use FPGA to simulate an elevator with two floors. 
>这是某高校数字电路实验II课设，已实现2022年秋季学期所有功能
## 软硬件配置
系统：win10
软件：Vivado 2018.3
开发板芯片：xc7a35tftg256-2
## 设计要求
1、实现2层楼的简易电梯控制系统。
2、电梯有4个按键。
1楼外只有向上按键（KEY0），2楼外只有向下按键（KEY1），电梯内还有2个按键分别为1楼按键(KEY2)和2楼按键(KEY3）。所有楼层外和电梯内的按键产生的信号作为给电梯的运行请求信号。
3、电梯有4个指示灯（LED0、 LED1 、 LED2 、 LED3）。
LED0: 按下KEY0键,若电梯不在1楼，则LED0亮。
LED1: 按下KEY1键,若电梯不在2楼，则LED1亮。
LED2: 电梯在1楼，按KEY3键, 则LED3亮，电梯到2楼后LED3灭。
LED3: 电梯在2楼，按KEY2键, 则LED2亮，电梯到1楼后LED2灭。
4、有2个数码管，分别显示当前运行状态及楼层。
（1）1个数码管显示当前运行状态，电梯有三个运行状态：待机、上行、下行。
 待机：电梯停在1楼或2楼且无请求信号时均为待机状态。
上行状态：电梯停在1楼，有KEY1或KEY3被按下时进入上行状态。
下行状态：电梯停在2楼，有KEY0或KEY2被按下时进入 下行状态。
（2）1个数码管显示所在楼层，显示1或2；每一层楼之间的运行时间间隔为３秒。
5、有2个拨码开关。
（1）复位开关。向下拨动后，电梯复位回到1楼。
（2）启动开关。向上拨动后，按键有效，电梯正常工作。
6、增加其它功能。
（1）电梯上行时，LED11至LED7五个指示灯从右到左每隔0.6秒点亮一个；
电梯下行时，LED7至LED11五个指示灯从左到右每隔0.6秒点亮一个。
（2）电梯运行到达新楼层时，蜂鸣器发出一声清晰“嘀”声。
（3）电梯开始上行或下行时，在最左边两个数码管上正计时显示运行时间0.0-2.9（秒），精度为0.1秒。到达新楼层时显示3.0（秒）。
（4）电梯上行时，楼层显示数码管前2秒显示1，后1秒显示2；
电梯下行时，楼层显示数码管前2秒显示2，后1秒显示1。
## 设计思路
容易得出的一个结论是：电梯一共有以下几种互相独立的状态——“在1楼”、“在上行过程中”、“在2楼”、“在下行过程中”。而4个楼层按键无非就是“上行”、“下行”两种。对于“下楼”而言，如果对前述4种状态依次考虑未免过于复杂。事实上，我们可以将4种状态化简为两种——“在1楼”和“不在1楼”。那么对于这两种状态，我们引出标志量floor1来表示：在1楼时标志量为1，否则为0。同理引出标志量floor2。
据此我们可以得到如下推论：当标志量floor1为0时，“下行”类按键按下时我们才应该控制电梯下行。同理，上行亦然。然而，这里有一个问题是：存在各有一个有效的“上行”、“下行”在较短的时间内按下的情况，它们将出现控制上的冲突。对此我们暂且延后考虑，前述内容对应代码如下：
```verilog
//电梯不在2楼，电梯内按下2楼键，等待上行
if(!floor2&&!key[3])begin
    //控制上行
end
//电梯不在1楼，电梯内按下1楼键，等待下行
if(!floor1&&!key[2])begin
    //控制下行
end
//电梯不在2楼，2楼外按下下楼键，等待上行
if(!floor2&&!key[1])begin
    //控制上行
end
//电梯不在1楼，1楼外按下上楼键，等待下行
if(!floor1&&!key[0])begin
    //控制下行
end
```
现在先考虑实现3秒运行、0.1秒间隔计时、每0.6秒点亮一个流水灯、前2秒显示前一楼层后1秒显示新楼层等功能。很容易想到使用计数的方式实现，并采用它们的最大因数100ms作为时钟信号。使用变量cnt对时钟信号进行计数，当计数到30时即完整运行了3秒。为了保障计数准确，我们在检测到“上行”、“下行”命令有效时便对cnt进行初始化赋零，计数到30后也进行清零。
引出了cnt之后，我们可以开始考虑冲突问题了。首先可以想到，为了对上行和下行时间分别计算，我们将由一个变量cnt计算运行时间改为分别用cnt1计算上行时间和用cnt2计算下行时间。显然，如果电梯正在上行即cnt1值介于0和30之间，“下行”类按键按下后，cnt2应先初始化赋零然后等到cnt1计算到30后清零，此时才能开始计数。如何让cnt2挂机后再进行计算呢？我们再引入新的标志量EN1和EN2。当有“上行”类按键按下并且指令有效（即前面说的floor2为0）时，将EN1赋值为1，表示有上行指令需要运行，直到上行结束即cnt1计数到30才重新将EN1赋值为0。EN2同理。因此我们可以做出以下判断：（1）当只有EN1有效（为1）时，对上行时间进行计数即对cnt1进行累加；（2）当只有EN2有效时，对下行时间进行计数即对cnt2进行累加；（3）当EN1和EN2同时有效时，由于上行按键和下行按键按下有时间差，那么cnt1和cnt2不会相同，且后按下的按键对应的计数值此时应该为0，则值更大的是更早按下的，此时我们应对值大的那个进行计数。应该注意到的是，在进行计数的时候应同时将对应的楼层状态量进行赋零，防止未能及时检测到有效输入。至此，冲突问题解决，上述实现代码如下：
```Verilog
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
```
考虑按键对应的LED灯。在根据标志量floor1和floor2判断按键按下功能有效后，我们就可以直接点亮对应的LED灯；在cnt1计数到30后，LED3和LED1同时设置为熄灭即可，不需要考虑原本亮着的是哪个；在cnt2计数到30后，LED2和LED0同时设置为熄灭。由此可以完善按键是否有效的检测代码以及清零部分代码如下：
```verilog
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
```
```verilog
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
```
考虑复位开关和启动开关。对于启动开关，我们只需要使用一个if语句将之前所有功能包含进去即可。而复位开关，虽然和启动开关同样是使用拨码开关，但由于要求复位时能经过3秒运行到1楼，在使用的时候有所区别。启动开关只需要判断当前启动开关对应变量的值，而复位开关若同样只根据当前对应变量的值进行判断，那么经过3秒运行到1楼的功能可能很难实现。正确做法应该是检测对应变量的瞬间变化即出现下降沿。笔者使用的方法是检测两个时钟信号之间对应变量的值是否一样，对应代码如下：
```verilog
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
    …… //别的东西
end
```
考虑流水灯。由于要求每0.6秒点亮一颗，即在我们的计数中，每6个时钟信号点亮一颗。设置计数到6、12、18、24、30各点亮一颗灯。同时，由于cnt1和cnt2不会同时为非零数，因此设置当两者之和小于6时使流水灯全部熄灭，这样可以使得二者不会冲突，具体实现代码如下：
```verilog
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
```
考虑蜂鸣器。笔者设置让蜂鸣器在到达前的0.2s开始响，即设置了当计数超过28后蜂鸣器才会响。而要让蜂鸣器响起，需要对蜂鸣器输入人耳听力频率范围内的方波。笔者设置的是周期为4ms即频率为250Hz的方波信号，通过分频得到2ms的时钟信号，检测到上升沿后对蜂鸣器状态进行翻转。实现代码如下：
```verilog
//“嘀”功能 响0.2s
always@(posedge clk_beep)begin
    if(cnt1>28||cnt2>28)begin   //周期为4ms，即250Hz
        beep=~beep; //占空比为50%
    end
    else beep=0;
end
```
考虑3秒计时器和楼层显示。两者都只需要通过对cnt1和cnt2的值进行判断，并使用数码管直接显示。需要注意的是应该对计时器的小数点单独进行控制。实现部分代码如下：
顶层文件中：
```verilog
decoder_7seg dec(
    .cnt(cnt1+cnt2),    //计时显示，由于二者不同时计数即至少有一个为0，因此取加
    .floor(datashow),   //楼层显示
    .seg(seg),
    .dig(dig),
    .clkin(clkin)
);
……
//楼层显示
if(0<cnt1&&cnt1<20)datashow=1;
else if(cnt1>=20)datashow=2;
if(0<cnt2&&cnt2<20)datashow=2;
else if(cnt2>=20)datashow=1;
```
数码管模块文件中：
```verilog
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
```
至此，设计所有功能均能完成。附录中给出完整代码，需要注意的是，为了让流水灯功能实现更加贴近真实情况，笔者在约束文件中将流水灯到为LED12到16，使其上下流动而非左右流动。
## 附录：完整代码
顶层文件：
```verilog
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
```
分频模块程序：
```verilog
module s_div (clkin,clkout,clkout2,clkout3);
    input   clkin;
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
```
按键消抖模块程序：
```verilog
module ajxd(
    input [3:0]btn_in,
    input btn_clk,
    output [3:0]btn_out
    );  
    reg  [3:0] btn0=0;//定义了btn0寄存器
    reg  [3:0] btn1=0;//定义了btn1寄存器
    reg  [3:0] btn2=0;//定义了btn2寄存器
    always@(posedge btn_clk)
    begin
        btn0<=btn_in;
        btn1<=btn0;
        btn2<=btn1;
    end
    assign btn_out=(btn2&btn1&btn0)|(~btn2&btn1&btn0);
endmodule
```
数码管显示模块程序：
```verilog
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
```
约束文件：
```verilog
set_property PACKAGE_PIN D4 [get_ports clkin]
set_property IOSTANDARD LVCMOS33 [get_ports clkin]

set_property PACKAGE_PIN T9 [get_ports power]
set_property IOSTANDARD LVCMOS33 [get_ports power]

set_property PACKAGE_PIN F3 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property PACKAGE_PIN L2 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]

set_property PACKAGE_PIN R12 [get_ports {col[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[0]}]
set_property PACKAGE_PIN T12 [get_ports {col[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[1]}]
set_property PACKAGE_PIN R11 [get_ports {col[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[2]}]
set_property PACKAGE_PIN T10 [get_ports {col[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[3]}]

set_property PACKAGE_PIN K3 [get_ports {row[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[0]}]
set_property PACKAGE_PIN M6 [get_ports {row[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[1]}]
set_property PACKAGE_PIN P10 [get_ports {row[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[2]}]
set_property PACKAGE_PIN R10 [get_ports {row[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[3]}]

set_property PACKAGE_PIN N11 [get_ports {dig[5]}]
set_property PACKAGE_PIN N14 [get_ports {dig[4]}]
set_property PACKAGE_PIN N13 [get_ports {dig[3]}]
set_property PACKAGE_PIN M12 [get_ports {dig[2]}]
set_property PACKAGE_PIN H13 [get_ports {dig[1]}]
set_property PACKAGE_PIN G12 [get_ports {dig[0]}]
set_property PACKAGE_PIN P11 [get_ports {seg[7]}]
set_property PACKAGE_PIN N12 [get_ports {seg[6]}]
set_property PACKAGE_PIN L14 [get_ports {seg[5]}]
set_property PACKAGE_PIN K13 [get_ports {seg[4]}]
set_property PACKAGE_PIN K12 [get_ports {seg[3]}]
set_property PACKAGE_PIN P13 [get_ports {seg[2]}]
set_property PACKAGE_PIN M14 [get_ports {seg[1]}]
set_property PACKAGE_PIN L13 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]


set_property PACKAGE_PIN P9 [get_ports {led[0]}]
set_property PACKAGE_PIN R8 [get_ports {led[1]}]
set_property PACKAGE_PIN R7 [get_ports {led[2]}]
set_property PACKAGE_PIN T5 [get_ports {led[3]}]
set_property PACKAGE_PIN N6 [get_ports {led[4]}]
set_property PACKAGE_PIN T4 [get_ports {led[5]}]
set_property PACKAGE_PIN T3 [get_ports {led[6]}]
set_property PACKAGE_PIN P5 [get_ports {led[7]}]
set_property PACKAGE_PIN P1 [get_ports {led[8]}]
set_property PACKAGE_PIN N1 [get_ports {led[9]}]
set_property PACKAGE_PIN M1 [get_ports {led[10]}]
set_property PACKAGE_PIN L4 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
```
