`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
           // Input Signals
           clk,
           rst_n,
           in_valid,
           direction,
           addr_dram,
           addr_sd,
           // Output Signals
           out_valid,
           out_data,
           // DRAM Signals
           AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
           AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
           // SD Signals
           MISO,
           MOSI
       );

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input             out_valid;
input      [7:0]  out_data;

// DRAM Signals
// write address channel
input      [31:0] AW_ADDR;
input             AW_VALID;
output            AW_READY;
// write data channel
input             W_VALID;
input      [63:0] W_DATA;
output            W_READY;
// write response channel
output            B_VALID;
output     [1:0]  B_RESP;
input             B_READY;
// read address channel
input      [31:0] AR_ADDR;
input             AR_VALID;
output            AR_READY;
// read data channel
output     [63:0] R_DATA;
output            R_VALID;
output     [1:0]  R_RESP;
input             R_READY;

// SD Signals
output            MISO;
input             MOSI;

real CYCLE = `CYCLE_TIME;
integer a;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;

always #(CYCLE / 2.0) clk = ~clk;

initial
begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    a = $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat=1;i_pat<=PAT_NUM;i_pat=i_pat+1)
    begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM); //Write down your DRAM Final State
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);		 //Write down your SD CARD Final State
    display_pass_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
integer SEED = 42;

reg        direction_reg;
reg [13:0] addr_dram_reg;
reg [15:0] addr_sd_reg;
reg [63:0] golden_out;

// check SPEC MAIN-1
task reset_signal_task;
    begin
        force clk     =   0;
        rst_n         =   1;
        in_valid      =   0;
        direction     = 'bx;
        addr_dram     = 'bx;
        addr_sd       = 'bx;
        total_latency =   0;

        #CYCLE rst_n  =   0;
        #CYCLE rst_n  =   1;

        #CYCLE;
        release clk;

        if(out_valid !== 0 || out_data !== 0 || AW_ADDR !== 0 || AW_VALID !== 0 || W_VALID !== 0 || W_DATA !== 0 || B_READY !== 0 || AR_ADDR !== 0 || AR_VALID !== 0 || R_READY !== 0 || MOSI !== 1)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                                   SPEC MAIN-1 FAIL                                                         ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
    end
endtask

task input_task;
    begin
        a = $fscanf(pat_read, "%d", direction_reg);
        a = $fscanf(pat_read, "%d", addr_dram_reg);
        a = $fscanf(pat_read, "%d", addr_sd_reg);
        repeat(($urandom(SEED) % 3 + 2)) @(negedge clk); // random delay for 2 ~ 4 cycle

        in_valid  =   1;
        direction = direction_reg;
        addr_dram = addr_dram_reg;
        addr_sd   = addr_sd_reg;
        @(negedge clk);
        in_valid  =   0;
        direction = 'bx;
        addr_dram = 'bx;
        addr_sd   = 'bx;
    end
endtask

// check SPEC MAIN-2
always @(*)
begin
    @(negedge clk);
    if((out_valid === 0 && out_data !== 0))
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC MAIN-2 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC MAIN-3
task wait_out_valid_task;
    begin
        latency = 0;
        while(out_valid === 0)
        begin
            latency = latency + 1;
            if(latency == 10000)
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   SPEC MAIN-3 FAIL                                                         ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end
endtask

// check SPEC MAIN-4、5、6
task check_ans_task;
    begin
        latency = 0;
        golden_out = (!direction_reg)? u_DRAM.DRAM[addr_dram_reg] : u_SD.SD[addr_sd_reg];
        while(out_valid === 1)
        begin
            latency = latency + 1;
            if(latency > 8)
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   SPEC MAIN-4 FAIL                                                         ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            if(u_DRAM.DRAM[addr_dram_reg] !== u_SD.SD[addr_sd_reg])
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   SPEC MAIN-6 FAIL                                                         ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            if((B_READY === 1 && B_VALID === 0) || (B_READY === 0 && B_VALID === 1)) // SPEC_MAIN_6_5
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   SPEC MAIN-6 FAIL                                                         ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            if((latency === 1 && out_data !== golden_out[63:56]) || (latency === 2 && out_data !== golden_out[55:48]) || (latency === 3 && out_data !== golden_out[47:40]) || (latency === 4 && out_data !== golden_out[39:32]) || (latency === 5 && out_data !== golden_out[31:24]) || (latency === 6 && out_data !== golden_out[23:16]) || (latency === 7 && out_data !== golden_out[15:8]) || (latency === 8 && out_data !== golden_out[7:0]))
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   SPEC MAIN-5 FAIL                                                         ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
        if(latency !== 8)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                                   SPEC MAIN-4 FAIL                                                         ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
    end
endtask

//////////////////////////////////////////////////////////////////////

task YOU_PASS_task;
    begin
        $display("*************************************************************************");
        $display("*                         Congratulations!                              *");
        $display("*                Your execution cycles = %5d cycles          *", total_latency);
        $display("*                Your clock period = %.1f ns          *", CYCLE);
        $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
        $display("*************************************************************************");
        $finish;
    end
endtask

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
        $display("*                                                        Your execution cycles = %5d cycles                                                  ", total_latency);
        $display("*                                                        Your clock period = %.1f ns                                                         ", CYCLE);
        $display("*                                                        Total Latency = %.1f ns                                                             ", total_latency*CYCLE);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end
endtask

task YOU_FAIL_task;
    begin
        $display("*                              FAIL!                                    *");
        $display("*                    Error message from PATTERN.v                       *");
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

pseudo_DRAM u_DRAM (
                .clk(clk),
                .rst_n(rst_n),
                // write address channel
                .AW_ADDR(AW_ADDR),
                .AW_VALID(AW_VALID),
                .AW_READY(AW_READY),
                // write data channel
                .W_VALID(W_VALID),
                .W_DATA(W_DATA),
                .W_READY(W_READY),
                // write response channel
                .B_VALID(B_VALID),
                .B_RESP(B_RESP),
                .B_READY(B_READY),
                // read address channel
                .AR_ADDR(AR_ADDR),
                .AR_VALID(AR_VALID),
                .AR_READY(AR_READY),
                // read data channel
                .R_DATA(R_DATA),
                .R_VALID(R_VALID),
                .R_RESP(R_RESP),
                .R_READY(R_READY)
            );

pseudo_SD u_SD (
              .clk(clk),
              .MOSI(MOSI),
              .MISO(MISO)
          );

endmodule
