//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC(
           // Input signals
           opt,
           in_n0, in_n1, in_n2, in_n3, in_n4,
           // Output signals
           out_n
       );

//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
input       [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
input       [2:0] opt;
output reg  [9:0] out_n;

//================================================================
//    Wire & Registers
//================================================================
// wire [3:0] lv0 [0:4];
// wire [3:0] lv1 [0:4];
// wire [3:0] lv2 [0:4];
// wire [3:0] lv3 [0:4];
// wire [3:0] lv4 [0:4];
reg  [3:0] lv5 [0:4];
reg  [4:0] sort_res [0:4];

reg signed [4:0] seq [0:4];

//================================================================
//    DESIGN
//================================================================

// Counting Sort ......
wire lv0_1 = (in_n0 > in_n1) ? 1'b1 : 1'b0;
wire lv0_2 = (in_n0 > in_n2) ? 1'b1 : 1'b0;
wire lv0_3 = (in_n0 > in_n3) ? 1'b1 : 1'b0;
wire lv0_4 = (in_n0 > in_n4) ? 1'b1 : 1'b0;

wire lv1_0 = ~lv0_1;
wire lv1_2 = (in_n1 > in_n2) ? 1'b1 : 1'b0;
wire lv1_3 = (in_n1 > in_n3) ? 1'b1 : 1'b0;
wire lv1_4 = (in_n1 > in_n4) ? 1'b1 : 1'b0;

wire lv2_0 = ~lv0_2;
wire lv2_1 = ~lv1_2;
wire lv2_3 = (in_n2 > in_n3) ? 1'b1 : 1'b0;
wire lv2_4 = (in_n2 > in_n4) ? 1'b1 : 1'b0;

wire lv3_0 = ~lv0_3;
wire lv3_1 = ~lv1_3;
wire lv3_2 = ~lv2_3;
wire lv3_4 = (in_n3 > in_n4) ? 1'b1 : 1'b0;

wire lv4_0 = ~lv0_4;
wire lv4_1 = ~lv1_4;
wire lv4_2 = ~lv2_4;
wire lv4_3 = ~lv3_4;

wire [2:0] addr_0 = lv0_1 + lv0_2 + lv0_3 + lv0_4;
wire [2:0] addr_1 = lv1_0 + lv1_2 + lv1_3 + lv1_4;
wire [2:0] addr_2 = lv2_0 + lv2_1 + lv2_3 + lv2_4;
wire [2:0] addr_3 = lv3_0 + lv3_1 + lv3_2 + lv3_4;
wire [2:0] addr_4 = lv4_0 + lv4_1 + lv4_2 + lv4_3;


always @(*)
begin
    lv5[0] = 0;
    lv5[1] = 0;
    lv5[2] = 0;
    lv5[3] = 0;
    lv5[4] = 0;
    lv5[addr_0] = in_n0;
    lv5[addr_1] = in_n1;
    lv5[addr_2] = in_n2;
    lv5[addr_3] = in_n3;
    lv5[addr_4] = in_n4;
end

always @(*)
begin
    if(opt[1] == 1) // large -> small
    begin
        sort_res[0] = lv5[4];
        sort_res[1] = lv5[3];
        sort_res[2] = lv5[2];
        sort_res[3] = lv5[1];
        sort_res[4] = lv5[0];
    end
    else // small -> large
    begin
        sort_res[0] = lv5[0];
        sort_res[1] = lv5[1];
        sort_res[2] = lv5[2];
        sort_res[3] = lv5[3];
        sort_res[4] = lv5[4];
    end
end

// Normalization ......
wire signed [4:0] sub;
assign sub = $signed({1'b0, ((sort_res[0] + sort_res[4]) >> 1)});

always @(*)
begin
    if(opt[0] == 1)
    begin
        seq[0] = $signed({1'b0, sort_res[0]}) - sub;
        seq[1] = $signed({1'b0, sort_res[1]}) - sub;
        seq[2] = $signed({1'b0, sort_res[2]}) - sub;
        seq[3] = $signed({1'b0, sort_res[3]}) - sub;
        seq[4] = $signed({1'b0, sort_res[4]}) - sub;
    end
    else
    begin 
        seq[0] = $signed({1'b0, sort_res[0]});
        seq[1] = $signed({1'b0, sort_res[1]});
        seq[2] = $signed({1'b0, sort_res[2]});
        seq[3] = $signed({1'b0, sort_res[3]});
        seq[4] = $signed({1'b0, sort_res[4]});
    end
end

// Calculation ......
wire signed [7:0] cal_avg;
reg  signed [4:0] avg;
assign cal_avg = seq[0] + seq[1] + seq[2] + seq[3] + seq[4];

always @(*) // -21 ~ 75
begin
    case (cal_avg)
        -35:                 avg = -7;
        -34,-33,-32,-31,-30: avg = -6;
        -29,-28,-27,-26,-25: avg = -5;
        -24,-23,-22,-21,-20: avg = -4;
        -19,-18,-17,-16,-15: avg = -3;
        -14,-13,-12,-11,-10: avg = -2;
        -9,-8,-7,-6,-5:      avg = -1;
        5,6,7,8,9:           avg =  1;
        10,11,12,13,14:      avg =  2;
        15,16,17,18,19:      avg =  3;
        20,21,22,23,24:      avg =  4;
        25,26,27,28,29:      avg =  5;
        30,31,32,33,34:      avg =  6;
        35,36,37,38,39:      avg =  7;
        40,41,42,43,44:      avg =  8;
        45,46,47,48,49:      avg =  9;
        50,51,52,53,54:      avg = 10;
        55,56,57,58,59:      avg = 11;
        60,61,62,63,64:      avg = 12;
        65,66,67,68,69:      avg = 13;
        70,71,72,73,74:      avg = 14;
        75:                  avg = 15;
        default:             avg =  0; // 0 ~ 4 default 0
    endcase 
end

// wire signed [9:0] mul_out0, mul_out1, mul_out2; 
// mul_table mul0(seq[0], seq[4], mul_out0);
// mul_table mul1(seq[1], seq[2], mul_out1);
// mul_table mul2(avg, seq[3], mul_out2);

wire signed [9:0] eq1, cal_eq0;
assign eq1     = ((seq[3] <<< 1) + seq[3] - seq[0] * seq[4]);
assign cal_eq0 = seq[0] + seq[1] * seq[2] + avg * seq[3];

reg  signed [9:0] eq0;

always @(*) 
begin
    case (cal_eq0)
        -51: eq0 = -17;
        -50: eq0 = -16;
        -49: eq0 = -16;
        -48: eq0 = -16;
        -47: eq0 = -15;
        -46: eq0 = -15;
        -45: eq0 = -15;
        -44: eq0 = -14;
        -43: eq0 = -14;
        -42: eq0 = -14;
        -41: eq0 = -13;
        -40: eq0 = -13;
        -39: eq0 = -13;
        -38: eq0 = -12;
        -37: eq0 = -12;
        -36: eq0 = -12;
        -35: eq0 = -11;
        -34: eq0 = -11;
        -33: eq0 = -11;
        -32: eq0 = -10;
        -31: eq0 = -10;
        -30: eq0 = -10;
        -29: eq0 = -9;
        -28: eq0 = -9;
        -27: eq0 = -9;
        -26: eq0 = -8;
        -25: eq0 = -8;
        -24: eq0 = -8;
        -23: eq0 = -7;
        -22: eq0 = -7;
        -21: eq0 = -7;
        -20: eq0 = -6;
        -19: eq0 = -6;
        -18: eq0 = -6;
        -17: eq0 = -5;
        -16: eq0 = -5;
        -15: eq0 = -5;
        -14: eq0 = -4;
        -13: eq0 = -4;
        -12: eq0 = -4;
        -11: eq0 = -3;
        -10: eq0 = -3;
        -9: eq0 = -3;
        -8: eq0 = -2;
        -7: eq0 = -2;
        -6: eq0 = -2;
        -5: eq0 = -1;
        -4: eq0 = -1;
        -3: eq0 = -1;
        -2: eq0 = 0;
        -1: eq0 = 0;
        0: eq0 = 0;
        1: eq0 = 0;
        2: eq0 = 0;
        3: eq0 = 1;
        4: eq0 = 1;
        5: eq0 = 1;
        6: eq0 = 2;
        7: eq0 = 2;
        8: eq0 = 2;
        9: eq0 = 3;
        10: eq0 = 3;
        11: eq0 = 3;
        12: eq0 = 4;
        13: eq0 = 4;
        14: eq0 = 4;
        15: eq0 = 5;
        16: eq0 = 5;
        17: eq0 = 5;
        18: eq0 = 6;
        19: eq0 = 6;
        20: eq0 = 6;
        21: eq0 = 7;
        22: eq0 = 7;
        23: eq0 = 7;
        24: eq0 = 8;
        25: eq0 = 8;
        26: eq0 = 8;
        27: eq0 = 9;
        28: eq0 = 9;
        29: eq0 = 9;
        30: eq0 = 10;
        31: eq0 = 10;
        32: eq0 = 10;
        33: eq0 = 11;
        34: eq0 = 11;
        35: eq0 = 11;
        36: eq0 = 12;
        37: eq0 = 12;
        38: eq0 = 12;
        39: eq0 = 13;
        40: eq0 = 13;
        41: eq0 = 13;
        42: eq0 = 14;
        43: eq0 = 14;
        44: eq0 = 14;
        45: eq0 = 15;
        46: eq0 = 15;
        47: eq0 = 15;
        48: eq0 = 16;
        49: eq0 = 16;
        50: eq0 = 16;
        51: eq0 = 17;
        52: eq0 = 17;
        53: eq0 = 17;
        54: eq0 = 18;
        55: eq0 = 18;
        56: eq0 = 18;
        57: eq0 = 19;
        58: eq0 = 19;
        59: eq0 = 19;
        60: eq0 = 20;
        61: eq0 = 20;
        62: eq0 = 20;
        63: eq0 = 21;
        64: eq0 = 21;
        65: eq0 = 21;
        66: eq0 = 22;
        67: eq0 = 22;
        68: eq0 = 22;
        69: eq0 = 23;
        70: eq0 = 23;
        71: eq0 = 23;
        72: eq0 = 24;
        73: eq0 = 24;
        74: eq0 = 24;
        75: eq0 = 25;
        76: eq0 = 25;
        77: eq0 = 25;
        78: eq0 = 26;
        79: eq0 = 26;
        80: eq0 = 26;
        81: eq0 = 27;
        82: eq0 = 27;
        83: eq0 = 27;
        84: eq0 = 28;
        85: eq0 = 28;
        86: eq0 = 28;
        87: eq0 = 29;
        88: eq0 = 29;
        89: eq0 = 29;
        90: eq0 = 30;
        91: eq0 = 30;
        92: eq0 = 30;
        93: eq0 = 31;
        94: eq0 = 31;
        95: eq0 = 31;
        96: eq0 = 32;
        97: eq0 = 32;
        98: eq0 = 32;
        99: eq0 = 33;
        100: eq0 = 33;
        101: eq0 = 33;
        102: eq0 = 34;
        103: eq0 = 34;
        104: eq0 = 34;
        105: eq0 = 35;
        106: eq0 = 35;
        107: eq0 = 35;
        108: eq0 = 36;
        109: eq0 = 36;
        110: eq0 = 36;
        111: eq0 = 37;
        112: eq0 = 37;
        113: eq0 = 37;
        114: eq0 = 38;
        115: eq0 = 38;
        116: eq0 = 38;
        117: eq0 = 39;
        118: eq0 = 39;
        119: eq0 = 39;
        120: eq0 = 40;
        121: eq0 = 40;
        122: eq0 = 40;
        123: eq0 = 41;
        124: eq0 = 41;
        125: eq0 = 41;
        126: eq0 = 42;
        127: eq0 = 42;
        128: eq0 = 42;
        129: eq0 = 43;
        130: eq0 = 43;
        131: eq0 = 43;
        132: eq0 = 44;
        133: eq0 = 44;
        134: eq0 = 44;
        135: eq0 = 45;
        136: eq0 = 45;
        137: eq0 = 45;
        138: eq0 = 46;
        139: eq0 = 46;
        140: eq0 = 46;
        141: eq0 = 47;
        142: eq0 = 47;
        143: eq0 = 47;
        144: eq0 = 48;
        145: eq0 = 48;
        146: eq0 = 48;
        147: eq0 = 49;
        148: eq0 = 49;
        149: eq0 = 49;
        150: eq0 = 50;
        151: eq0 = 50;
        152: eq0 = 50;
        153: eq0 = 51;
        154: eq0 = 51;
        155: eq0 = 51;
        156: eq0 = 52;
        157: eq0 = 52;
        158: eq0 = 52;
        159: eq0 = 53;
        160: eq0 = 53;
        161: eq0 = 53;
        162: eq0 = 54;
        163: eq0 = 54;
        164: eq0 = 54;
        165: eq0 = 55;
        166: eq0 = 55;
        167: eq0 = 55;
        168: eq0 = 56;
        169: eq0 = 56;
        170: eq0 = 56;
        171: eq0 = 57;
        172: eq0 = 57;
        173: eq0 = 57;
        174: eq0 = 58;
        175: eq0 = 58;
        176: eq0 = 58;
        177: eq0 = 59;
        178: eq0 = 59;
        179: eq0 = 59;
        180: eq0 = 60;
        181: eq0 = 60;
        182: eq0 = 60;
        183: eq0 = 61;
        184: eq0 = 61;
        185: eq0 = 61;
        186: eq0 = 62;
        187: eq0 = 62;
        188: eq0 = 62;
        189: eq0 = 63;
        190: eq0 = 63;
        191: eq0 = 63;
        192: eq0 = 64;
        193: eq0 = 64;
        194: eq0 = 64;
        195: eq0 = 65;
        196: eq0 = 65;
        197: eq0 = 65;
        198: eq0 = 66;
        199: eq0 = 66;
        200: eq0 = 66;
        201: eq0 = 67;
        202: eq0 = 67;
        203: eq0 = 67;
        204: eq0 = 68;
        205: eq0 = 68;
        206: eq0 = 68;
        207: eq0 = 69;
        208: eq0 = 69;
        209: eq0 = 69;
        210: eq0 = 70;
        211: eq0 = 70;
        212: eq0 = 70;
        213: eq0 = 71;
        214: eq0 = 71;
        215: eq0 = 71;
        216: eq0 = 72;
        217: eq0 = 72;
        218: eq0 = 72;
        219: eq0 = 73;
        220: eq0 = 73;
        221: eq0 = 73;
        222: eq0 = 74;
        223: eq0 = 74;
        224: eq0 = 74;
        225: eq0 = 75;
        226: eq0 = 75;
        227: eq0 = 75;
        228: eq0 = 76;
        229: eq0 = 76;
        230: eq0 = 76;
        231: eq0 = 77;
        232: eq0 = 77;
        233: eq0 = 77;
        234: eq0 = 78;
        235: eq0 = 78;
        236: eq0 = 78;
        237: eq0 = 79;
        238: eq0 = 79;
        239: eq0 = 79;
        240: eq0 = 80;
        241: eq0 = 80;
        242: eq0 = 80;
        243: eq0 = 81;
        244: eq0 = 81;
        245: eq0 = 81;
        246: eq0 = 82;
        247: eq0 = 82;
        248: eq0 = 82;
        249: eq0 = 83;
        250: eq0 = 83;
        251: eq0 = 83;
        252: eq0 = 84;
        253: eq0 = 84;
        254: eq0 = 84;
        255: eq0 = 85;
        256: eq0 = 85;
        257: eq0 = 85;
        258: eq0 = 86;
        259: eq0 = 86;
        260: eq0 = 86;
        261: eq0 = 87;
        262: eq0 = 87;
        263: eq0 = 87;
        264: eq0 = 88;
        265: eq0 = 88;
        266: eq0 = 88;
        267: eq0 = 89;
        268: eq0 = 89;
        269: eq0 = 89;
        270: eq0 = 90;
        271: eq0 = 90;
        272: eq0 = 90;
        273: eq0 = 91;
        274: eq0 = 91;
        275: eq0 = 91;
        276: eq0 = 92;
        277: eq0 = 92;
        278: eq0 = 92;
        279: eq0 = 93;
        280: eq0 = 93;
        281: eq0 = 93;
        282: eq0 = 94;
        283: eq0 = 94;
        284: eq0 = 94;
        285: eq0 = 95;
        286: eq0 = 95;
        287: eq0 = 95;
        288: eq0 = 96;
        289: eq0 = 96;
        290: eq0 = 96;
        291: eq0 = 97;
        292: eq0 = 97;
        293: eq0 = 97;
        294: eq0 = 98;
        295: eq0 = 98;
        296: eq0 = 98;
        297: eq0 = 99;
        298: eq0 = 99;
        299: eq0 = 99;
        300: eq0 = 100;
        301: eq0 = 100;
        302: eq0 = 100;
        303: eq0 = 101;
        304: eq0 = 101;
        305: eq0 = 101;
        306: eq0 = 102;
        307: eq0 = 102;
        308: eq0 = 102;
        309: eq0 = 103;
        310: eq0 = 103;
        311: eq0 = 103;
        312: eq0 = 104;
        313: eq0 = 104;
        314: eq0 = 104;
        315: eq0 = 105;
        316: eq0 = 105;
        317: eq0 = 105;
        318: eq0 = 106;
        319: eq0 = 106;
        320: eq0 = 106;
        321: eq0 = 107;
        322: eq0 = 107;
        323: eq0 = 107;
        324: eq0 = 108;
        325: eq0 = 108;
        326: eq0 = 108;
        327: eq0 = 109;
        328: eq0 = 109;
        329: eq0 = 109;
        330: eq0 = 110;
        331: eq0 = 110;
        332: eq0 = 110;
        333: eq0 = 111;
        334: eq0 = 111;
        335: eq0 = 111;
        336: eq0 = 112;
        337: eq0 = 112;
        338: eq0 = 112;
        339: eq0 = 113;
        340: eq0 = 113;
        341: eq0 = 113;
        342: eq0 = 114;
        343: eq0 = 114;
        344: eq0 = 114;
        345: eq0 = 115;
        346: eq0 = 115;
        347: eq0 = 115;
        348: eq0 = 116;
        349: eq0 = 116;
        350: eq0 = 116;
        351: eq0 = 117;
        352: eq0 = 117;
        353: eq0 = 117;
        354: eq0 = 118;
        355: eq0 = 118;
        356: eq0 = 118;
        357: eq0 = 119;
        358: eq0 = 119;
        359: eq0 = 119;
        360: eq0 = 120;
        361: eq0 = 120;
        362: eq0 = 120;
        363: eq0 = 121;
        364: eq0 = 121;
        365: eq0 = 121;
        366: eq0 = 122;
        367: eq0 = 122;
        368: eq0 = 122;
        369: eq0 = 123;
        370: eq0 = 123;
        371: eq0 = 123;
        372: eq0 = 124;
        373: eq0 = 124;
        374: eq0 = 124;
        375: eq0 = 125;
        376: eq0 = 125;
        377: eq0 = 125;
        378: eq0 = 126;
        379: eq0 = 126;
        380: eq0 = 126;
        381: eq0 = 127;
        382: eq0 = 127;
        383: eq0 = 127;
        384: eq0 = 128;
        385: eq0 = 128;
        386: eq0 = 128;
        387: eq0 = 129;
        388: eq0 = 129;
        389: eq0 = 129;
        390: eq0 = 130;
        391: eq0 = 130;
        392: eq0 = 130;
        393: eq0 = 131;
        394: eq0 = 131;
        395: eq0 = 131;
        396: eq0 = 132;
        397: eq0 = 132;
        398: eq0 = 132;
        399: eq0 = 133;
        400: eq0 = 133;
        401: eq0 = 133;
        402: eq0 = 134;
        403: eq0 = 134;
        404: eq0 = 134;
        405: eq0 = 135;
        406: eq0 = 135;
        407: eq0 = 135;
        408: eq0 = 136;
        409: eq0 = 136;
        410: eq0 = 136;
        411: eq0 = 137;
        412: eq0 = 137;
        413: eq0 = 137;
        414: eq0 = 138;
        415: eq0 = 138;
        416: eq0 = 138;
        417: eq0 = 139;
        418: eq0 = 139;
        419: eq0 = 139;
        420: eq0 = 140;
        421: eq0 = 140;
        422: eq0 = 140;
        423: eq0 = 141;
        424: eq0 = 141;
        425: eq0 = 141;
        426: eq0 = 142;
        427: eq0 = 142;
        428: eq0 = 142;
        429: eq0 = 143;
        430: eq0 = 143;
        431: eq0 = 143;
        432: eq0 = 144;
        433: eq0 = 144;
        434: eq0 = 144;
        435: eq0 = 145;
        436: eq0 = 145;
        437: eq0 = 145;
        438: eq0 = 146;
        439: eq0 = 146;
        440: eq0 = 146;
        441: eq0 = 147;
        442: eq0 = 147;
        443: eq0 = 147;
        444: eq0 = 148;
        445: eq0 = 148;
        446: eq0 = 148;
        447: eq0 = 149;
        448: eq0 = 149;
        449: eq0 = 149;
        450: eq0 = 150;
        451: eq0 = 150;
        452: eq0 = 150;
        453: eq0 = 151;
        454: eq0 = 151;
        455: eq0 = 151;
        456: eq0 = 152;
        457: eq0 = 152;
        458: eq0 = 152;
        459: eq0 = 153;
        460: eq0 = 153;
        461: eq0 = 153;
        462: eq0 = 154;
        463: eq0 = 154;
        464: eq0 = 154;
        465: eq0 = 155; 
        default: eq0 = 0;
    endcase
end 

always @(*)
begin
    if (opt[2] == 1)  out_n = (!eq1[9])? eq1 : ~(eq1 - 1'b1);
    else              out_n = eq0;
end
endmodule

// Area: 18617.861159