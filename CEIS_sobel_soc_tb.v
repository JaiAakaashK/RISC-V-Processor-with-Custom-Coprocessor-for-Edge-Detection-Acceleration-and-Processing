`timescale 1ns/1ps
module CEIS_sobel_soc_tb;

localparam IMG_W=640; localparam IMG_H=480;
localparam IMG_PIXELS=IMG_W*IMG_H; localparam PIX_W=12;
localparam VALID_PIXELS=(IMG_W-3)*(IMG_H-3);
localparam INSTR_ADDI_A0=32'h00000513; localparam INSTR_ADDI_A1=32'h00000593;
localparam INSTR_SOBEL=32'h00B5000B;   localparam INSTR_LOOP=32'h0000006F;

reg clk, reset;
CEIS_Top #(.IMG_W(IMG_W),.IMG_H(IMG_H),.PIX_W(PIX_W),.MEM_WORDS(8192)) dut(.clk(clk),.reset(reset));
initial clk=0; always #5 clk=~clk;

integer i, fd, pass_count, fail_count;
initial begin pass_count=0; fail_count=0; end

// PHASE 1
reg phase1_done, sobel_en_seen;
initial begin phase1_done=0; sobel_en_seen=0; end
always @(posedge clk) if(!phase1_done && dut.sobel_enable) sobel_en_seen=1;

initial begin
    reset=0;
    for(i=0;i<8192;i=i+1)       dut.cpu_mem[i]      =32'h0;
    for(i=0;i<IMG_PIXELS;i=i+1) dut.sobel_in_mem[i] ={PIX_W{1'b0}};
    for(i=0;i<IMG_PIXELS;i=i+1) dut.sobel_out_mem[i]={PIX_W{1'b0}};
    #50; reset=1; @(posedge clk);
    for(i=0;i<32;i=i+1) dut.cpu.registerFile[i]=32'h0;
    dut.cpu_mem[  0]=32'h00A00093; // SETUP_x1
    dut.cpu_mem[  1]=32'h00300113; // SETUP_x2
    dut.cpu_mem[  2]=32'hFFF00193; // SETUP_x3
    dut.cpu_mem[  3]=32'h00100213; // SETUP_x4
    dut.cpu_mem[  4]=32'h002082B3; // ADD
    dut.cpu_mem[  5]=32'h7C502823; // SAVE_ADD
    dut.cpu_mem[  6]=32'h40208333; // SUB
    dut.cpu_mem[  7]=32'h7C602A23; // SAVE_SUB
    dut.cpu_mem[  8]=32'h002213B3; // SLL
    dut.cpu_mem[  9]=32'h0020A433; // SLT
    dut.cpu_mem[ 10]=32'h0020B4B3; // SLTU
    dut.cpu_mem[ 11]=32'h0020C533; // XOR
    dut.cpu_mem[ 12]=32'h7CA02E23; // SAVE_XOR
    dut.cpu_mem[ 13]=32'h0020D5B3; // SRL
    dut.cpu_mem[ 14]=32'h7EB02023; // SAVE_SRL
    dut.cpu_mem[ 15]=32'h4021D633; // SRA
    dut.cpu_mem[ 16]=32'h0020E6B3; // OR
    dut.cpu_mem[ 17]=32'h0020F733; // AND
    dut.cpu_mem[ 18]=32'h7CE02C23; // SAVE_AND
    dut.cpu_mem[ 19]=32'h0070A813; // SLTI
    dut.cpu_mem[ 20]=32'h00F0B893; // SLTIU
    dut.cpu_mem[ 21]=32'h0FF0C913; // XORI
    dut.cpu_mem[ 22]=32'h0FF0E993; // ORI
    dut.cpu_mem[ 23]=32'h00C0FA13; // ANDI
    dut.cpu_mem[ 24]=32'h00221A93; // SLLI
    dut.cpu_mem[ 25]=32'h0010DB13; // SRLI
    dut.cpu_mem[ 26]=32'h4011DB93; // SRAI
    dut.cpu_mem[ 27]=32'hABCDEC37; // LUI
    dut.cpu_mem[ 28]=32'h00001C97; // AUIPC
    dut.cpu_mem[ 29]=32'h18102823; // SW_A
    dut.cpu_mem[ 30]=32'h18302A23; // SW_B
    dut.cpu_mem[ 31]=32'h18201C23; // SH_C
    dut.cpu_mem[ 32]=32'h0FF00293; // PREP_SB
    dut.cpu_mem[ 33]=32'h18500E23; // SB_D
    dut.cpu_mem[ 34]=32'h19002D03; // LW
    dut.cpu_mem[ 35]=32'h19401D83; // LH
    dut.cpu_mem[ 36]=32'h19405E03; // LHU
    dut.cpu_mem[ 37]=32'h19400E83; // LB
    dut.cpu_mem[ 38]=32'h19404F03; // LBU
    dut.cpu_mem[ 39]=32'h19805F83; // LHU2
    dut.cpu_mem[ 40]=32'h022082B3; // MUL
    dut.cpu_mem[ 41]=32'h32502023; // ST_MUL
    dut.cpu_mem[ 42]=32'h022092B3; // MULH
    dut.cpu_mem[ 43]=32'h32502223; // ST_MULH
    dut.cpu_mem[ 44]=32'h0220A2B3; // MULHSU
    dut.cpu_mem[ 45]=32'h32502423; // ST_MULHSU
    dut.cpu_mem[ 46]=32'h0220B2B3; // MULHU
    dut.cpu_mem[ 47]=32'h32502623; // ST_MULHU
    dut.cpu_mem[ 48]=32'h0220C2B3; // DIV
    dut.cpu_mem[ 49]=32'h32502823; // ST_DIV
    dut.cpu_mem[ 50]=32'h0220D2B3; // DIVU
    dut.cpu_mem[ 51]=32'h32502A23; // ST_DIVU
    dut.cpu_mem[ 52]=32'h0220E2B3; // REM
    dut.cpu_mem[ 53]=32'h32502C23; // ST_REM
    dut.cpu_mem[ 54]=32'h0220F2B3; // REMU
    dut.cpu_mem[ 55]=32'h32502E23; // ST_REMU
    dut.cpu_mem[ 56]=32'h00100313; // PREP_BEQ
    dut.cpu_mem[ 57]=32'h00108463; // BEQ
    dut.cpu_mem[ 58]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 59]=32'h00000013; // NOP
    dut.cpu_mem[ 60]=32'h4A602823; // CHK
    dut.cpu_mem[ 61]=32'h00100313; // PREP_BNE
    dut.cpu_mem[ 62]=32'h00209463; // BNE
    dut.cpu_mem[ 63]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 64]=32'h00000013; // NOP
    dut.cpu_mem[ 65]=32'h4A602A23; // CHK
    dut.cpu_mem[ 66]=32'h00100313; // PREP_BLT
    dut.cpu_mem[ 67]=32'h00114463; // BLT
    dut.cpu_mem[ 68]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 69]=32'h00000013; // NOP
    dut.cpu_mem[ 70]=32'h4A602C23; // CHK
    dut.cpu_mem[ 71]=32'h00100313; // PREP_BGE
    dut.cpu_mem[ 72]=32'h0020D463; // BGE
    dut.cpu_mem[ 73]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 74]=32'h00000013; // NOP
    dut.cpu_mem[ 75]=32'h4A602E23; // CHK
    dut.cpu_mem[ 76]=32'h00100313; // PREP_BLT
    dut.cpu_mem[ 77]=32'h00116463; // BLTU
    dut.cpu_mem[ 78]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 79]=32'h00000013; // NOP
    dut.cpu_mem[ 80]=32'h4C602023; // CHK
    dut.cpu_mem[ 81]=32'h00100313; // PREP_BGE
    dut.cpu_mem[ 82]=32'h0020F463; // BGEU
    dut.cpu_mem[ 83]=32'hEAD00013; // DEAD
    dut.cpu_mem[ 84]=32'h00000013; // NOP
    dut.cpu_mem[ 85]=32'h4C602223; // CHK
    dut.cpu_mem[ 86]=32'h008007EF; // JAL
    dut.cpu_mem[ 87]=32'hEAD00013; // JAL_SKIP
    dut.cpu_mem[ 88]=32'h00000013; // JAL_LAND
    dut.cpu_mem[ 89]=32'h01078767; // JALR
    dut.cpu_mem[ 90]=32'hEAD00013; // JALR_SKIP
    dut.cpu_mem[ 91]=32'h00000013; // JALR_LAND
    dut.cpu_mem[ 92]=32'h00000513; // SOBEL_A0
    dut.cpu_mem[ 93]=32'h00000593; // SOBEL_A1
    dut.cpu_mem[ 94]=32'h00B5000B; // SOBEL
    dut.cpu_mem[ 95]=32'h0000006F; // PARK
    repeat(2500) @(posedge clk);
    $display(""); $display("=================================================================");
    $display("  PHASE 1 - RV32IM Full Instruction Test (96 instructions)");
    $display("  %-32s  %-12s  %-12s  %s","Operation","Expected","Actual","Result");
    $display("  %s","-------------------------------------------------------------------");
    $display("  %-32s  0x%08h  0x%08h  %s","addi x1,x0,10   (source=10)",32'h0000000A,dut.cpu.registerFile[1],(dut.cpu.registerFile[1]===32'h0000000A)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[1]===32'h0000000A) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","addi x2,x0,3    (source=3)",32'h00000003,dut.cpu.registerFile[2],(dut.cpu.registerFile[2]===32'h00000003)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[2]===32'h00000003) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","addi x3,x0,-1   (source=-1)",32'hFFFFFFFF,dut.cpu.registerFile[3],(dut.cpu.registerFile[3]===32'hFFFFFFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[3]===32'hFFFFFFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","addi x4,x0,1    (source=1)",32'h00000001,dut.cpu.registerFile[4],(dut.cpu.registerFile[4]===32'h00000001)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[4]===32'h00000001) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","sll x7,x4,x2 → 8",32'h00000008,dut.cpu.registerFile[7],(dut.cpu.registerFile[7]===32'h00000008)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[7]===32'h00000008) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","slt x8,x1,x2 → 0",32'h00000000,dut.cpu.registerFile[8],(dut.cpu.registerFile[8]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[8]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","sltu x9,x1,x2 → 0",32'h00000000,dut.cpu.registerFile[9],(dut.cpu.registerFile[9]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[9]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","sra x12,x3,x2 → -1",32'hFFFFFFFF,dut.cpu.registerFile[12],(dut.cpu.registerFile[12]===32'hFFFFFFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[12]===32'hFFFFFFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","or x13,x1,x2 → 11",32'h0000000B,dut.cpu.registerFile[13],(dut.cpu.registerFile[13]===32'h0000000B)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[13]===32'h0000000B) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","slti  x16,x1,7   → 0",32'h00000000,dut.cpu.registerFile[16],(dut.cpu.registerFile[16]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[16]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","sltiu x17,x1,15  → 1",32'h00000001,dut.cpu.registerFile[17],(dut.cpu.registerFile[17]===32'h00000001)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[17]===32'h00000001) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","xori  x18,x1,255 → 0xF5",32'h000000F5,dut.cpu.registerFile[18],(dut.cpu.registerFile[18]===32'h000000F5)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[18]===32'h000000F5) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","ori   x19,x1,255 → 0xFF",32'h000000FF,dut.cpu.registerFile[19],(dut.cpu.registerFile[19]===32'h000000FF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[19]===32'h000000FF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","andi  x20,x1,12  → 8",32'h00000008,dut.cpu.registerFile[20],(dut.cpu.registerFile[20]===32'h00000008)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[20]===32'h00000008) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","slli  x21,x4,2   → 4",32'h00000004,dut.cpu.registerFile[21],(dut.cpu.registerFile[21]===32'h00000004)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[21]===32'h00000004) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","srli  x22,x1,1   → 5",32'h00000005,dut.cpu.registerFile[22],(dut.cpu.registerFile[22]===32'h00000005)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[22]===32'h00000005) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","srai x23,x3,1 → -1",32'hFFFFFFFF,dut.cpu.registerFile[23],(dut.cpu.registerFile[23]===32'hFFFFFFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[23]===32'hFFFFFFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lui x24,0xABCDE → 0xABCDE000",32'hABCDE000,dut.cpu.registerFile[24],(dut.cpu.registerFile[24]===32'hABCDE000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[24]===32'hABCDE000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","auipc x25,1 → PC+0x1000",32'h00001070,dut.cpu.registerFile[25],(dut.cpu.registerFile[25]===32'h00001070)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[25]===32'h00001070) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lw  x26,400(x0) → 10",32'h0000000A,dut.cpu.registerFile[26],(dut.cpu.registerFile[26]===32'h0000000A)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[26]===32'h0000000A) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lh  x27,404(x0) → -1",32'hFFFFFFFF,dut.cpu.registerFile[27],(dut.cpu.registerFile[27]===32'hFFFFFFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[27]===32'hFFFFFFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lhu x28,404(x0) → 0xFFFF",32'h0000FFFF,dut.cpu.registerFile[28],(dut.cpu.registerFile[28]===32'h0000FFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[28]===32'h0000FFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lb  x29,404(x0) → -1",32'hFFFFFFFF,dut.cpu.registerFile[29],(dut.cpu.registerFile[29]===32'hFFFFFFFF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[29]===32'hFFFFFFFF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lbu x30,404(x0) → 0xFF",32'h000000FF,dut.cpu.registerFile[30],(dut.cpu.registerFile[30]===32'h000000FF)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[30]===32'h000000FF) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","lhu x31,408(x0) → 3",32'h00000003,dut.cpu.registerFile[31],(dut.cpu.registerFile[31]===32'h00000003)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[31]===32'h00000003) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","jal x15,+8 → skip DEAD, x15=PC+4",32'h0000015C,dut.cpu.registerFile[15],(dut.cpu.registerFile[15]===32'h0000015C)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[15]===32'h0000015C) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","jalr x14,x15,16 → skip DEAD, x14",32'h00000168,dut.cpu.registerFile[14],(dut.cpu.registerFile[14]===32'h00000168)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[14]===32'h00000168) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","addi a0,x0,0",32'h00000000,dut.cpu.registerFile[10],(dut.cpu.registerFile[10]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[10]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","addi a1,x0,0",32'h00000000,dut.cpu.registerFile[11],(dut.cpu.registerFile[11]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[11]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;

    // Results saved to memory (registers clobbered by later instructions)
    $display("  %-32s  0x%08h  0x%08h  %s","ADD  x1+x2=13",32'h0000000D,dut.cpu_mem[500],(dut.cpu_mem[500]===32'h0000000D)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[500]===32'h0000000D) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","SUB  x1-x2=7",32'h00000007,dut.cpu_mem[501],(dut.cpu_mem[501]===32'h00000007)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[501]===32'h00000007) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","AND  x1&x2=2",32'h00000002,dut.cpu_mem[502],(dut.cpu_mem[502]===32'h00000002)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[502]===32'h00000002) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","XOR  x1^x2=9",32'h00000009,dut.cpu_mem[503],(dut.cpu_mem[503]===32'h00000009)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[503]===32'h00000009) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","SRL  x1>>x2=1",32'h00000001,dut.cpu_mem[504],(dut.cpu_mem[504]===32'h00000001)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[504]===32'h00000001) pass_count=pass_count+1; else fail_count=fail_count+1;

    // M-extension results
    $display("  %-32s  0x%08h  0x%08h  %s","MUL  x1*x2=30",32'h0000001E,dut.cpu_mem[200],(dut.cpu_mem[200]===32'h0000001E)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[200]===32'h0000001E) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","MULH upper=0",32'h00000000,dut.cpu_mem[201],(dut.cpu_mem[201]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[201]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","MULHSU=0",32'h00000000,dut.cpu_mem[202],(dut.cpu_mem[202]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[202]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","MULHU=0",32'h00000000,dut.cpu_mem[203],(dut.cpu_mem[203]===32'h00000000)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[203]===32'h00000000) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","DIV  10/3=3",32'h00000003,dut.cpu_mem[204],(dut.cpu_mem[204]===32'h00000003)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[204]===32'h00000003) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","DIVU 10/3=3",32'h00000003,dut.cpu_mem[205],(dut.cpu_mem[205]===32'h00000003)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[205]===32'h00000003) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","REM  10%3=1",32'h00000001,dut.cpu_mem[206],(dut.cpu_mem[206]===32'h00000001)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[206]===32'h00000001) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","REMU 10%3=1",32'h00000001,dut.cpu_mem[207],(dut.cpu_mem[207]===32'h00000001)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[207]===32'h00000001) pass_count=pass_count+1; else fail_count=fail_count+1;

    // Branch sentinel values (1=taken)
    $display("  %-32s  0x%08h  0x%08h  %s","BEQ  x1,x1,+8  (taken)",32'h1,dut.cpu_mem[300],(dut.cpu_mem[300]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[300]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","BNE  x1,x2,+8  (taken)",32'h1,dut.cpu_mem[301],(dut.cpu_mem[301]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[301]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","BLT  x2<x1     (taken)",32'h1,dut.cpu_mem[302],(dut.cpu_mem[302]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[302]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","BGE  x1>=x2    (taken)",32'h1,dut.cpu_mem[303],(dut.cpu_mem[303]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[303]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","BLTU x2<x1 uns (taken)",32'h1,dut.cpu_mem[304],(dut.cpu_mem[304]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[304]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  0x%08h  0x%08h  %s","BGEU x1>=x2    (taken)",32'h1,dut.cpu_mem[305],(dut.cpu_mem[305]===32'h1)?"[PASS]":"[FAIL]");
    if(dut.cpu_mem[305]===32'h1) pass_count=pass_count+1; else fail_count=fail_count+1;

    $display("  %-32s  %-12s  0x%08h  %s","JAL  x15=PC+4","non-zero",dut.cpu.registerFile[15],(dut.cpu.registerFile[15]!==32'h0)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[15]!==32'h0) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  %-12s  0x%08h  %s","JALR x14=PC+4","non-zero",dut.cpu.registerFile[14],(dut.cpu.registerFile[14]!==32'h0)?"[PASS]":"[FAIL]");
    if(dut.cpu.registerFile[14]!==32'h0) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %-32s  %-12s  %-12s  %s","SOBEL EN pulse","1",sobel_en_seen?"1":"0",sobel_en_seen?"[PASS]":"[FAIL]");
    if(sobel_en_seen) pass_count=pass_count+1; else fail_count=fail_count+1;
    $display("  %s","-------------------------------------------------------------------");
    $display("  Phase 1 result: %0d PASS  %0d FAIL", pass_count, fail_count);
    $display("=================================================================");
    phase1_done=1;
end

// PHASE 2
integer pixel_count; initial pixel_count=0;
always @(posedge clk) if(dut.sobel_out_valid && phase1_done) pixel_count=pixel_count+1;
always @(posedge clk)
    if(phase1_done && dut.sobel_out_valid && (pixel_count%50000==0))
        $display("[SOBEL] Pixels: %0d / %0d  t=%0t ns",pixel_count,VALID_PIXELS,$time);

integer cpu_cycle; reg last_en,last_busy;
initial begin cpu_cycle=0; last_en=0; last_busy=0; end
always @(posedge clk) begin
    if(reset && phase1_done) begin
        cpu_cycle=cpu_cycle+1;
        if(cpu_cycle<=30||dut.sobel_enable!==last_en||dut.sobel_busy!==last_busy||cpu_cycle%5000==0)
            $display("[CPU] t=%0t  PC=%08H  EN=%b  BUSY=%b  PIX=%0d",
                $time,dut.cpu.PC,dut.sobel_enable,dut.sobel_busy,pixel_count);
        last_en=dut.sobel_enable; last_busy=dut.sobel_busy;
    end
end

initial begin
    wait(phase1_done);
    $display(""); $display("=================================================================");
    $display("  PHASE 2 - Full Sobel SoC Test (640x480)");
    $display("=================================================================");
    reset=0; #50;
    for(i=0;i<8192;i=i+1)       dut.cpu_mem[i]      =32'h0;
    for(i=0;i<IMG_PIXELS;i=i+1) dut.sobel_in_mem[i] ={{PIX_W{{1'b0}}}};
    for(i=0;i<IMG_PIXELS;i=i+1) dut.sobel_out_mem[i]={{PIX_W{{1'b0}}}};
    $readmemh("E:/CEIS/program.hex",dut.cpu_mem);
    $readmemh("E:/CEIS/airplane_00391_image_hex.txt",dut.sobel_in_mem);
    if(dut.cpu_mem[0]!==INSTR_ADDI_A0) dut.cpu_mem[0]=INSTR_ADDI_A0;
    if(dut.cpu_mem[1]!==INSTR_ADDI_A1) dut.cpu_mem[1]=INSTR_ADDI_A1;
    if(dut.cpu_mem[2]!==INSTR_SOBEL)   dut.cpu_mem[2]=INSTR_SOBEL;
    if(dut.cpu_mem[3]!==INSTR_LOOP)    dut.cpu_mem[3]=INSTR_LOOP;
    $display("[TB] cpu_mem[0..3]: 0x%08H 0x%08H 0x%08H 0x%08H",
             dut.cpu_mem[0],dut.cpu_mem[1],dut.cpu_mem[2],dut.cpu_mem[3]);
    $display("[TB] sobel_in_mem[0..4]: %03h %03h %03h %03h %03h",
             dut.sobel_in_mem[0],dut.sobel_in_mem[1],dut.sobel_in_mem[2],
             dut.sobel_in_mem[3],dut.sobel_in_mem[4]);
    if(dut.sobel_in_mem[0]===12'h0 && dut.sobel_in_mem[1]===12'h0)
        $display("[TB] WARNING: image all zeros!"); else $display("[TB] Image loaded OK.");
    reset=1;
end

always @(posedge clk) begin
    if(phase1_done && pixel_count==VALID_PIXELS) begin
        $display("[TB] Sobel complete - %0d pixels at t=%0t ns",VALID_PIXELS,$time);
        fd=$fopen("E:/CEIS/sobel_output.pgm","w");
        if(fd==0) begin $display("[TB] ERROR: cannot open PGM"); $finish; end
        $fdisplay(fd,"P2"); $fdisplay(fd,"# Sobel SoC output");
        $fdisplay(fd,"%0d %0d",IMG_W,IMG_H); $fdisplay(fd,"255");
        for(i=0;i<IMG_PIXELS;i=i+1) $fdisplay(fd,"%0d",dut.sobel_out_mem[i]&12'hFF);
        $fclose(fd);
        $display("[TB] PGM saved to E:/CEIS/sobel_output.pgm");
        $display(""); $display("=================================================================");
        $display("  ALL TESTS COMPLETE");
        $display("  Phase 1 (RV32IM) : %0d PASS  %0d FAIL",pass_count,fail_count);
        $display("  Phase 2 (Sobel)  : %0d pixels processed",pixel_count);
        $display("=================================================================");
        $finish;
    end
end

reg [31:0] last_pc; integer stall_idle_cycles; reg sobel_ever_enabled;
initial begin last_pc=32'hFFFFFFFF; stall_idle_cycles=0; sobel_ever_enabled=0; end
always @(posedge clk) begin
    if(reset && phase1_done) begin
        if(dut.sobel_enable) sobel_ever_enabled=1;
        if(dut.cpu.PC!==last_pc) begin stall_idle_cycles=0; last_pc=dut.cpu.PC; end
        else if(!dut.sobel_busy) begin
            stall_idle_cycles=stall_idle_cycles+1;
            if(stall_idle_cycles==50 && !sobel_ever_enabled) begin $display("[TB] ERROR: stall before sobel"); $finish; end
            if(stall_idle_cycles==5000 && sobel_ever_enabled) begin $display("[TB] ERROR: no pixels after sobel"); $finish; end
        end else stall_idle_cycles=0;
    end
end
initial begin #200_000_000; $display("[TB] TIMEOUT pix=%0d",pixel_count); $finish; end
initial begin $dumpfile("E:/CEIS/soc_wave.vcd"); $dumpvars(0,CEIS_sobel_soc_tb); end
endmodule