//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_DRAM(
           clk, rst_n,
           AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
           AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
       );

input             clk, rst_n;
// write address channel
input      [31:0] AW_ADDR;
input             AW_VALID;
output reg        AW_READY;
// write data channel
input             W_VALID;
input      [63:0] W_DATA;
output reg        W_READY;
// write response channel
output reg        B_VALID;
output reg [1:0]  B_RESP;
input             B_READY;
// read address channel
input      [31:0] AR_ADDR;
input             AR_VALID;
output reg        AR_READY;
// read data channel
output reg [63:0] R_DATA;
output reg        R_VALID;
output reg [1:0]  R_RESP;
input             R_READY;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";

//================================================================
// wire & registers
//================================================================
reg [63:0] DRAM [0:8191];
reg [63:0] W_DATA_reg;
reg        flag1, flag2, flag3;
reg [31:0] AW_ADDR_reg, AR_ADDR_reg;

integer cnt1, cnt2, cnt3;
integer SEED = 42;
integer MAX_LATENCY = 100;

initial
begin
    $readmemh(DRAM_p_r, DRAM);
    RESET;
    while(1)
    begin
        WRITE;
        // check read
        READ;
        @(negedge clk);
    end
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task RESET;
    begin
        AW_READY = 0;
        W_READY  = 0;
        B_VALID  = 0;
        B_RESP   = 0;
        AR_READY = 0;
        R_DATA   = 0;
        R_VALID  = 0;
        R_RESP   = 0;
    end
endtask

// write address channel
task WRITE;
    begin
        // write address channel (AW)
        if(AW_VALID === 1)
        begin
            AW_ADDR_reg = AW_ADDR;
            repeat(($urandom(SEED) % 3) + 1) @(posedge clk);
            AW_READY = 1;
            @(posedge clk) AW_READY = 0;

            // write data channel (W)
            repeat(($urandom(SEED) % 3) + 1) @(posedge clk);
            W_READY = 1;
            wait(W_VALID === 1);
            DRAM[AW_ADDR_reg] = W_DATA;
            @(posedge clk) W_READY = 0;

            // write response channel (B)
            repeat(($urandom(SEED) % 3) + 1) @(posedge clk);
            B_VALID = 1;
            wait(B_READY == 1);
            @(posedge clk) B_VALID = 0;
        end
    end
endtask

task READ;
    begin
        // read address channel (AR)
        if(AR_VALID === 1)
        begin
            AR_ADDR_reg = AR_ADDR;
            repeat(($urandom(SEED) % 3) + 1) @(posedge clk);
            AR_READY = 1;
            @(posedge clk) AR_READY = 0;

            // read data channel (R)
            repeat(($urandom(SEED) % 3) + 1) @(posedge clk);
            R_VALID = 1;
            R_DATA = DRAM[AR_ADDR_reg];
            wait(R_READY === 1);
            @(posedge clk) R_VALID = 0;
            R_DATA = 0;
        end
    end
endtask

// check SPEC DRAM-1
always @(*)
begin
    @(negedge clk);
    if((AR_VALID === 0 && AR_ADDR !== 0) || (AW_VALID === 0 && AW_ADDR !== 0) || (W_VALID === 0 && W_DATA !== 0))
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-1 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC DRAM-2
always @(*)
begin
    @(negedge clk);
    if(AW_ADDR > 8191 || AR_ADDR > 8191)
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-2 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC DRAM-3-1
always @(*)
begin
    @(negedge clk);
    flag1 = 0;
    while(AR_VALID === 1 && AR_ADDR === AR_ADDR_reg)
    begin
        if(AR_READY === 0)
            flag1 = 1;
        else
            flag1 = 0;
        @(negedge clk);
    end
    if(flag1 === 1)
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-3 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC DRAM-3-2
always @(*)
begin
    @(negedge clk);
    flag2 = 0;
    while(AW_VALID === 1 && AW_ADDR === AW_ADDR_reg)
    begin
        if(AW_READY === 0)
            flag2 = 1;
        else
            flag2 = 0;
        @(negedge clk);
    end
    if(flag2 === 1)
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-3 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC DRAM-3-3
always @(*)
begin
    @(negedge clk);
    flag3 = 0;
    while(R_READY === 1)
    begin
        if(R_VALID === 0)
            flag3 = 1;
        else
            flag3 = 0;
        @(negedge clk);
    end
    if(flag3 === 1)
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-3 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end

// check SPEC DRAM-3-4
always @(*)
begin
    @(negedge clk);
    wait(W_VALID === 1);
    W_DATA_reg = W_DATA;
    wait(W_READY === 1);
    if(W_DATA !== W_DATA_reg)
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-3 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end
// check SPEC DRAM-4
always @(*) // DRAM-4-1
begin
    cnt1 = 0;
    wait(AR_READY === 1);
    wait(AR_READY === 0);
    while (R_READY === 0)
    begin
        cnt1 = cnt1 + 1; // counter++
        if(cnt1 > MAX_LATENCY)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                                   SPEC DRAM-4 FAIL                                                         ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
end

always @(*) // DRAM-4-2
begin
    cnt2 = 0;
    wait(AW_READY === 1);
    wait(AW_READY === 0);
    while (W_VALID === 0)
    begin
        cnt2 = cnt2 + 1; // counter++
        if(cnt2 > MAX_LATENCY)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                                   SPEC DRAM-4 FAIL                                                         ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
end

always @(*) // DRAM-4-3
begin
    cnt3 = 0;
    wait(B_VALID === 1);
    while (B_READY === 0)
    begin
        cnt3 = cnt3 + 1; // counter++
        if(cnt3 > MAX_LATENCY)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                                   SPEC DRAM-4 FAIL                                                         ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
end

// check SPEC DRAM-5
always @(*)
begin
    @(negedge clk);
    if(((AR_READY === 1 || AR_VALID === 1) && R_READY === 1) || ((AW_READY === 1 || AW_VALID === 1) && W_VALID === 1))
    begin
        display_fail_task;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                                   SPEC DRAM-5 FAIL                                                         ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
end



//////////////////////////////////////////////////////////////////////

task YOU_FAIL_task;
    begin
        $display("*                              FAIL!                                    *");
        $display("*                 Error message from pseudo_DRAM.v                      *");
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

