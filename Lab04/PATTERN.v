//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME 5

module PATTERN(
           //Output Port
           clk,
           rst_n,
           in_valid,
           Img,
           Kernel,
           Weight,
           Opt,
           //Input Port
           out_valid,
           out
       );

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
output reg        clk, rst_n, in_valid;
output reg [31:0] Img;
output reg [31:0] Kernel;
output reg [31:0] Weight;
output reg [1:0]  Opt;
input             out_valid;
input      [31:0] out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

parameter inst_sig_width       = 23;
parameter inst_exp_width       = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type       = 0;
parameter inst_arch            = 0;

real CYCLE = `CYCLE_TIME;

integer a;
integer SEED = 42;
integer pat_read, ans_read;
integer PAT_NUM;
integer total_lat, lat;
integer i_pat;
integer i;

reg [31:0] Img_reg    [0:47];
reg [31:0] Kernel_reg [0:26];
reg [31:0] Weight_reg [0:3];
reg [1:0]  Opt_reg;
reg [31:0] golden_out [0:3];

always #(CYCLE / 2.0) clk = ~clk;

initial
begin
    pat_read = $fopen("../00_TESTBED/input.txt", "r");
    ans_read = $fopen("../00_TESTBED/output.txt", "r");

    reset_signal_task;

    i_pat = 0;
    total_lat = 0;
    a = $fscanf(pat_read, "%d", PAT_NUM);
    a = $fscanf(ans_read, "%d", PAT_NUM);

    for (i_pat=1;i_pat<=PAT_NUM;i_pat=i_pat+1)
    begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_lat = total_lat + lat;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);
    $fclose(ans_read);

    display_pass_task;
end

task reset_signal_task;
    begin
        force clk     =   0;
        rst_n         =   1;
        in_valid      =   0;
        total_lat     =   0;
        Img           = 'bx;
        Kernel        = 'bx;
        Weight        = 'bx;
        Opt           = 'bx;

        #CYCLE rst_n  =   0;
        #CYCLE rst_n  =   1;

        #CYCLE;
        release clk;

        if(out_valid !== 0 || out !== 0)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                            Output signal should be reset                                                   ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
    end
endtask

task input_task;
    begin
        a = $fscanf(pat_read, "%d", Opt_reg);
        for (i=0;i<48;i=i+1)
            a = $fscanf(pat_read, "%h", Img_reg[i]);
        for (i=0;i<27;i=i+1)
            a = $fscanf(pat_read, "%h", Kernel_reg[i]);
        for (i=0;i<4;i=i+1)
            a = $fscanf(pat_read, "%h", Weight_reg[i]);

        repeat(($urandom(SEED) % 3 + 2)) @(negedge clk); // random delay for 2 ~ 4 cycle

        in_valid = 1;

        for (i=0;i<48;i=i+1)
        begin
            Opt      = (i < 1)? Opt_reg : 'bx;
            Img      = Img_reg[i];
            Kernel   = (i < 27)? Kernel_reg[i] : 'bx;
            Weight   = (i < 4)? Weight_reg[i] : 'bx;
            @(negedge clk);
        end

        Img      = 'bx;
        in_valid = 0;
    end
endtask

task wait_out_valid_task;
    begin
        lat = 0;
        while(out_valid === 0)
        begin
            lat = lat + 1;
            if(lat == 1000)
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                          execution latency over 1000 cycles!                                               ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
        total_lat = total_lat + lat;
    end
endtask

real sign, exp, fraction;
real out_value;
real golden_value[0:3];
real error_value[0:3];

task check_ans_task;
    begin
        lat = 0;
        for (i=0;i<4;i=i+1)
        begin
            a = $fscanf(ans_read, "%h", golden_out[i]);
            golden_value[i]  = $bitstoshortreal(golden_out[i]);
        end

        while(out_valid === 1)
        begin
            lat = lat + 1;
            out_value = $bitstoshortreal(out);
            error_value[lat-1] = $abs(out_value - golden_value[lat-1]) / golden_value[lat-1];
            if(lat > 4)
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                         out_valid should be high for 4 cycles                                              ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            if(error_value[lat-1] > 0.02)
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                       FAIL!                                                                ");
                $display ("                                                                      Code %d                                                               ", lat-1);
                $display ("                                           Your out is   : %b = %f                                                                          ",out,out_value);
                $display ("                                           ans should be : %b = %f                                                                          ",golden_out[lat-1], golden_value[lat-1]);
                $display ("                                           error         : %f                                                                               ",error_value[lat-1]);
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
        if(lat !== 4)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                         out_valid should be high for 4 cycles                                              ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
    end
endtask

always @(*)
begin
    @(negedge clk);
    if((out_valid === 0 && out !== 0))
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                        out should be reset when out_valid is 0                                             ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// display pass task
task display_pass_task;
    begin
        $display("\033[1;33m                         `oo+oy+`                                                                                                     ");
        $display("\033[1;33m                        /h/----+y        `+++++:                                                                                      ");
        $display("\033[1;33m                      .y------:m/+ydoo+:y:---:+o                                                                                      ");
        $display("\033[1;33m                       o+------/y--::::::+oso+:/y                                                                                     ");
        $display("\033[1;33m                       s/-----:/:----------:+ooy+-                                                                                    ");
        $display("\033[1;33m                      /o----------------/yhyo/::/o+/:-.`                                                                              ");
        $display("\033[1;33m                     `ys----------------:::--------:::+yyo+                                                                           ");
        $display("\033[1;33m                     .d/:-------------------:--------/--/hos/                                                                         ");
        $display("\033[1;33m                     y/-------------------::ds------:s:/-:sy-                                                                         ");
        $display("\033[1;33m                    +y--------------------::os:-----:ssm/o+`                                                                          ");
        $display("\033[1;33m                   `d:-----------------------:-----/+o++yNNmms                                                                        ");
        $display("\033[1;33m                    /y-----------------------------------hMMMMN.                                                                      ");
        $display("\033[1;33m                    o+---------------------://:----------:odmdy/+.                                                                    ");
        $display("\033[1;33m                    o+---------------------::y:------------::+o-/h                                                                    ");
        $display("\033[1;33m                    :y-----------------------+s:------------/h:-:d                                                                    ");
        $display("\033[1;33m                    `m/-----------------------+y/---------:oy:--/y                                                                    ");
        $display("\033[1;33m                     /h------------------------:os++/:::/+o/:--:h-                                                                    ");
        $display("\033[1;33m                  `:+ym--------------------------://++++o/:---:h/                                                                     ");
        $display("\033[1;31m                 `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
        $display("\033[1;31m                  shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
        $display("\033[1;31m                  .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
        $display("\033[1;31m                 `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
        $display("\033[1;31m                 -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
        $display("\033[1;31m                  hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
        $display("\033[1;31m                  `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
        $display("\033[1;31m                   dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
        $display("\033[1;31m                  :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
        $display("\033[1;31m                 /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
        $display("\033[1;31m               +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
        $display("\033[1;31m               -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
        $display("\033[1;31m                `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
        $display("\033[1;31m                  os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
        $display("\033[1;33m                  h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
        $display("\033[1;33m                  m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
        $display("\033[1;33m                 `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
        $display("\033[1;33m                 .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
        $display("\033[1;33m                 +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
        $display("\033[1;33m                 h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
        $display("\033[1;33m                `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
        $display("\033[1;33m             `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
        $display("\033[1;33m            -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
        $display("\033[1;33m            s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
        $display("\033[1;33m            o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
        $display("\033[1;33m             :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
        $display("\033[1;33m                .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
        $display("\033[1;33m                                                   `:+omy/---------------------+h:----:y+//so                                         ");
        $display("\033[1;33m                                                       `-ys:-------------------+s-----+s///om                                         ");
        $display("\033[1;33m                                                          -os+::---------------/y-----ho///om                                         ");
        $display("\033[1;33m                                                             -+oo//:-----------:h-----h+///+d                                         ");
        $display("\033[1;33m                                                                `-oyy+:---------s:----s/////y                                         ");
        $display("\033[1;33m                                                                    `-/o+::-----:+----oo///+s                                         ");
        $display("\033[1;33m                                                                        ./+o+::-------:y///s:                                         ");
        $display("\033[1;33m                                                                            ./+oo/-----oo/+h                                          ");
        $display("\033[1;33m                                                                                `://++++syo`                                          ");
        $display("\033[1;0m");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                               Congratulations!                						                       ");
        $display("*                                                        Your execution cycles = %5d cycles                                                  ", total_lat);
        $display("*                                                        Your clock period = %.1f ns                                                         ", CYCLE);
        $display("*                                                        Total Latency = %.1f ns                                                             ", total_lat*CYCLE);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end
endtask

// display fail task
task display_fail_task;
    begin
        $display("                                                                                              ");
        $display("                                                                 ./+oo+/.                     ");
        $display("                                                                /s:-----+s`                   ");
        $display("                                                                y/-------:y                   ");
        $display("                                                           `.-:/od+/------y`                  ");
        $display("                                             `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                                            -m+:::::::---------------------::o+.              ");
        $display("                                           `hod-------------------------------:o+             ");
        $display("                                     ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                                    /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                                  -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                                -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                               -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                               y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                               h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                               h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                               s:----------------/s+///------------------------------o`       ");
        $display("                         ``..../s------------------::--------------------------------o        ");
        $display("                     -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("                    /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("                  -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("                `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display("               .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display("               s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("              `h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("              `h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display("               s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display("               .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("                /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("                `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("              `+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("              +yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display("               /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display("               .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display("               y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("              `h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("              /s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("              +s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("              +s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("              /s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display("              .h--------------------------:::/++oooooooo+++/:::----------o`                   ");
    end
endtask

endmodule


