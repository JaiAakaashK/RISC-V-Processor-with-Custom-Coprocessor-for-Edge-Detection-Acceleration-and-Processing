// FemtoRV32 "electron" RV32IM + Sobel coprocessor interface
// Fixed for ModelSim -vlog01compat: all declarations moved to top of module.

`define NRV_ARCH     "rv32im"
`define NRV_ABI      "ilp32"
`define NRV_OPTIMIZE "-O3"

module CEIS_sobel_rvcore(
    input          clk,
    output  [31:0] mem_addr,
    output  [31:0] mem_wdata,
    output   [3:0] mem_wmask,
    input   [31:0] mem_rdata,
    output         mem_rstrb,
    input          mem_rbusy,
    input          mem_wbusy,
    input          reset,
    // Sobel coprocessor interface
    input          sobel_busy,
    output reg     sobel_enable,
    output reg [31:0] sobel_in_addr,
    output reg [31:0] sobel_out_addr
);

    parameter RESET_ADDR = 32'h00000000;
    parameter ADDR_WIDTH = 24;

    // =========================================================================
    // ALL DECLARATIONS FIRST  (required for -vlog01compat)
    // =========================================================================

    // --- Instruction register & PC ---
    reg  [31:2] instr;
    reg  [ADDR_WIDTH-1:0] PC;

    // --- Register file ---
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [31:0] registerFile [0:31];

    // --- State machine ---
    localparam FETCH_INSTR_bit     = 0;
    localparam WAIT_INSTR_bit      = 1;
    localparam EXECUTE_bit         = 2;
    localparam WAIT_ALU_OR_MEM_bit = 3;
    localparam NB_STATES           = 4;

    localparam FETCH_INSTR     = 1 << FETCH_INSTR_bit;
    localparam WAIT_INSTR      = 1 << WAIT_INSTR_bit;
    localparam EXECUTE         = 1 << EXECUTE_bit;
    localparam WAIT_ALU_OR_MEM = 1 << WAIT_ALU_OR_MEM_bit;

    (* onehot *)
    reg [NB_STATES-1:0] state;

    // --- Instruction decode wires ---
    wire [4:0]  rdId;
    (* onehot *)
    wire [7:0]  funct3Is;
    wire [31:0] Uimm, Iimm, Simm, Bimm, Jimm;
    wire        isLoad, isALUimm, isAUIPC, isStore, isALUreg;
    wire        isLUI, isBranch, isJALR, isJAL, isSYSTEM;
    wire        is_sobel;
    wire        isALU;

    // --- ALU wires ---
    wire [31:0] aluIn1, aluIn2;
    wire        aluWr;
    wire [31:0] aluPlus;
    wire [32:0] aluMinus;
    wire        LT, LTU, EQ;
    wire [31:0] shifter_in;
    wire [31:0] shifter;
    wire [31:0] leftshift;
    wire        funcM, isDivide, aluBusy;
    wire        isMULH, isMULHSU;
    wire        sign1, sign2;
    wire signed [32:0] signed1, signed2;
    wire signed [63:0] multiply;
    wire [31:0] aluOut_base, aluOut_muldiv, aluOut;

    // --- Divider registers and wires ---
    reg  [31:0] dividend;
    reg  [62:0] divisor;
    reg  [31:0] quotient;
    reg  [31:0] quotient_msk;
    wire        divstep_do;
    wire [31:0] dividendN, quotientN;
    wire        div_sign;
    reg  [31:0] divResult;

    // --- Writeback ---
    wire        writeBack;
    wire [31:0] writeBackData;

    // --- Branch predicate ---
    wire predicate;

    // --- PC wires ---
    wire [ADDR_WIDTH-1:0] PCplus4;
    wire [ADDR_WIDTH-1:0] PCplusImm;
    wire [ADDR_WIDTH-1:0] loadstore_addr;
    wire [ADDR_WIDTH-1:0] PC_new;
    wire        jumpToPCplusImm;
    wire        needToWait;

    // --- Load/store ---
    wire        mem_byteAccess, mem_halfwordAccess;
    wire        LOAD_sign;
    wire [31:0] LOAD_data;
    wire [15:0] LOAD_halfword;
    wire  [7:0] LOAD_byte;
    wire  [3:0] STORE_wmask;

    // --- CSR / cycle counter ---
    reg  [63:0] cycles;
    wire        sel_cyclesh;
    wire [31:0] CSR_read;

    // =========================================================================
    // LOGIC (assignments and always blocks)
    // =========================================================================

    // --- Instruction decode ---
    assign rdId     = instr[11:7];
    assign funct3Is = 8'b00000001 << instr[14:12];

    assign Uimm = {    instr[31],   instr[30:12], {12{1'b0}}};
    assign Iimm = {{21{instr[31]}}, instr[30:20]};
    assign Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    assign Bimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign Jimm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    assign isLoad   = (instr[6:2] == 5'b00000);
    assign isALUimm = (instr[6:2] == 5'b00100);
    assign isAUIPC  = (instr[6:2] == 5'b00101);
    assign isStore  = (instr[6:2] == 5'b01000);
    assign isALUreg = (instr[6:2] == 5'b01100);
    assign isLUI    = (instr[6:2] == 5'b01101);
    assign isBranch = (instr[6:2] == 5'b11000);
    assign isJALR   = (instr[6:2] == 5'b11001);
    assign isJAL    = (instr[6:2] == 5'b11011);
    assign isSYSTEM = (instr[6:2] == 5'b11100);
    assign is_sobel = (instr[6:2] == 5'b00010);
    assign isALU    = isALUimm | isALUreg;

    // --- Register file write ---
    always @(posedge clk) begin
        if (writeBack)
            if (rdId != 0)
                registerFile[rdId] <= writeBackData;
    end

    // --- ALU inputs ---
    assign aluIn1  = rs1;
    assign aluIn2  = isALUreg | isBranch ? rs2 : Iimm;
    assign aluPlus = aluIn1 + aluIn2;
    assign aluMinus= {1'b1, ~aluIn2} + {1'b0, aluIn1} + 33'b1;
    assign LT      = (aluIn1[31] ^ aluIn2[31]) ? aluIn1[31] : aluMinus[32];
    assign LTU     = aluMinus[32];
    assign EQ      = (aluMinus[31:0] == 0);

    // --- Shifter ---
    assign shifter_in = funct3Is[1] ?
        {aluIn1[ 0],aluIn1[ 1],aluIn1[ 2],aluIn1[ 3],aluIn1[ 4],aluIn1[ 5],
         aluIn1[ 6],aluIn1[ 7],aluIn1[ 8],aluIn1[ 9],aluIn1[10],aluIn1[11],
         aluIn1[12],aluIn1[13],aluIn1[14],aluIn1[15],aluIn1[16],aluIn1[17],
         aluIn1[18],aluIn1[19],aluIn1[20],aluIn1[21],aluIn1[22],aluIn1[23],
         aluIn1[24],aluIn1[25],aluIn1[26],aluIn1[27],aluIn1[28],aluIn1[29],
         aluIn1[30],aluIn1[31]} : aluIn1;

    /* verilator lint_off WIDTH */
    assign shifter = $signed({instr[30] & aluIn1[31], shifter_in}) >>> aluIn2[4:0];
    /* verilator lint_on WIDTH */

    assign leftshift = {
        shifter[ 0],shifter[ 1],shifter[ 2],shifter[ 3],shifter[ 4],
        shifter[ 5],shifter[ 6],shifter[ 7],shifter[ 8],shifter[ 9],
        shifter[10],shifter[11],shifter[12],shifter[13],shifter[14],
        shifter[15],shifter[16],shifter[17],shifter[18],shifter[19],
        shifter[20],shifter[21],shifter[22],shifter[23],shifter[24],
        shifter[25],shifter[26],shifter[27],shifter[28],shifter[29],
        shifter[30],shifter[31]};

    // --- MUL/DIV ---
    assign funcM    = instr[25];
    assign isDivide = isALUreg & funcM & instr[14];
    assign aluBusy  = |quotient_msk;

    assign isMULH   = funct3Is[1];
    assign isMULHSU = funct3Is[2];
    assign sign1    = aluIn1[31] &  isMULH;
    assign sign2    = aluIn2[31] & (isMULH | isMULHSU);
    assign signed1  = {sign1, aluIn1};
    assign signed2  = {sign2, aluIn2};
    assign multiply = signed1 * signed2;

    // --- ALU output ---
    assign aluOut_base =
        (funct3Is[0] ? instr[30] & instr[5] ? aluMinus[31:0] : aluPlus : 32'b0) |
        (funct3Is[1] ? leftshift  : 32'b0) |
        (funct3Is[2] ? {31'b0,LT} : 32'b0) |
        (funct3Is[3] ? {31'b0,LTU}: 32'b0) |
        (funct3Is[4] ? aluIn1 ^ aluIn2 : 32'b0) |
        (funct3Is[5] ? shifter    : 32'b0) |
        (funct3Is[6] ? aluIn1 | aluIn2 : 32'b0) |
        (funct3Is[7] ? aluIn1 & aluIn2 : 32'b0);

    assign aluOut_muldiv =
        (  funct3Is[0]   ? multiply[31: 0] : 32'b0) |
        ( |funct3Is[3:1] ? multiply[63:32] : 32'b0) |
        (  instr[14]     ? div_sign ? -divResult : divResult : 32'b0);

    assign aluOut = isALUreg & funcM ? aluOut_muldiv : aluOut_base;

    // --- Divider ---
    assign divstep_do = divisor <= {31'b0, dividend};
    assign dividendN  = divstep_do ? dividend - divisor[31:0] : dividend;
    assign quotientN  = divstep_do ? quotient | quotient_msk  : quotient;
    assign div_sign   = ~instr[12] & (instr[13] ? aluIn1[31] :
                         (aluIn1[31] != aluIn2[31]) & |aluIn2);

    always @(posedge clk) begin
        if (isDivide & aluWr) begin
            dividend     <= ~instr[12] & aluIn1[31] ? -aluIn1 : aluIn1;
            divisor      <= {(~instr[12] & aluIn2[31] ? -aluIn2 : aluIn2), 31'b0};
            quotient     <= 0;
            quotient_msk <= 1 << 31;
        end else begin
            dividend     <= dividendN;
            divisor      <= divisor >> 1;
            quotient     <= quotientN;
            quotient_msk <= quotient_msk >> 1;
        end
    end

    always @(posedge clk)
        divResult <= instr[13] ? dividendN : quotientN;

    // --- Sobel coprocessor trigger ---
    always @(posedge clk) begin
        sobel_enable <= 1'b0;
        if (is_sobel & !sobel_busy) begin
            sobel_enable   <= 1'b1;
            sobel_in_addr  <= rs1;
            sobel_out_addr <= rs2;
        end
    end

    // --- Branch predicate ---
    assign predicate =
        funct3Is[0] &  EQ  |
        funct3Is[1] & !EQ  |
        funct3Is[4] &  LT  |
        funct3Is[5] & !LT  |
        funct3Is[6] &  LTU |
        funct3Is[7] & !LTU;

    // --- PC computation ---
    assign PCplus4   = PC + 4;
    assign PCplusImm = PC + (instr[3] ? Jimm[ADDR_WIDTH-1:0] :
                             instr[4] ? Uimm[ADDR_WIDTH-1:0] :
                                        Bimm[ADDR_WIDTH-1:0]);

    assign loadstore_addr = rs1[ADDR_WIDTH-1:0] +
                            (instr[5] ? Simm[ADDR_WIDTH-1:0] : Iimm[ADDR_WIDTH-1:0]);

    /* verilator lint_off WIDTH */
    assign mem_addr = state[WAIT_INSTR_bit] | state[FETCH_INSTR_bit] ?
                      PC : loadstore_addr;
    /* verilator lint_on WIDTH */

    // --- Cycle counter & CSR ---
    always @(posedge clk) cycles <= cycles + 1;
    assign sel_cyclesh = (instr[31:20] == 12'hC80);
    assign CSR_read    = sel_cyclesh ? cycles[63:32] : cycles[31:0];

    // --- Writeback ---
    assign writeBack = ~(isBranch | isStore) &
                       (state[EXECUTE_bit] | state[WAIT_ALU_OR_MEM_bit]);

    /* verilator lint_off WIDTH */
    assign writeBackData =
        (isSYSTEM         ? CSR_read  : 32'b0) |
        (isLUI            ? Uimm      : 32'b0) |
        (isALU            ? aluOut    : 32'b0) |
        (isAUIPC          ? PCplusImm : 32'b0) |
        (isJALR | isJAL   ? PCplus4   : 32'b0) |
        (isLoad           ? LOAD_data : 32'b0);
    /* verilator lint_on WIDTH */

    // --- Load/store ---
    assign mem_byteAccess     = (instr[13:12] == 2'b00);
    assign mem_halfwordAccess = (instr[13:12] == 2'b01);

    assign LOAD_sign     = !instr[14] & (mem_byteAccess ? LOAD_byte[7] : LOAD_halfword[15]);
    assign LOAD_halfword = loadstore_addr[1] ? mem_rdata[31:16] : mem_rdata[15:0];
    assign LOAD_byte     = loadstore_addr[0] ? LOAD_halfword[15:8] : LOAD_halfword[7:0];
    assign LOAD_data     = mem_byteAccess     ? {{24{LOAD_sign}},     LOAD_byte}     :
                           mem_halfwordAccess ? {{16{LOAD_sign}}, LOAD_halfword} :
                                                mem_rdata;

    assign mem_wdata[ 7: 0] = rs2[7:0];
    assign mem_wdata[15: 8] = loadstore_addr[0] ? rs2[7:0]  : rs2[15: 8];
    assign mem_wdata[23:16] = loadstore_addr[1] ? rs2[7:0]  : rs2[23:16];
    assign mem_wdata[31:24] = loadstore_addr[0] ? rs2[7:0]  :
                              loadstore_addr[1] ? rs2[15:8] : rs2[31:24];

    assign STORE_wmask =
        mem_byteAccess ?
            (loadstore_addr[1] ?
                (loadstore_addr[0] ? 4'b1000 : 4'b0100) :
                (loadstore_addr[0] ? 4'b0010 : 4'b0001)) :
        mem_halfwordAccess ?
            (loadstore_addr[1] ? 4'b1100 : 4'b0011) :
        4'b1111;

    // --- Memory control ---
    assign mem_rstrb = state[EXECUTE_bit] & isLoad | state[FETCH_INSTR_bit];
    assign mem_wmask = {4{state[EXECUTE_bit] & isStore}} & STORE_wmask;
    assign aluWr     = state[EXECUTE_bit] & isALU;

    assign jumpToPCplusImm = isJAL | (isBranch & predicate);
    assign needToWait      = isLoad | isStore | isDivide | is_sobel;

    assign PC_new = isJALR          ? {aluPlus[ADDR_WIDTH-1:1], 1'b0} :
                    jumpToPCplusImm ? PCplusImm :
                                      PCplus4;

    // --- State machine ---
    always @(posedge clk) begin
        if (!reset) begin
            state <= WAIT_ALU_OR_MEM;
            PC    <= RESET_ADDR[ADDR_WIDTH-1:0];
        end else
        (* parallel_case *)
        case (1'b1)
            state[WAIT_INSTR_bit]: begin
                if (!mem_rbusy) begin
                    rs1   <= registerFile[mem_rdata[19:15]];
                    rs2   <= registerFile[mem_rdata[24:20]];
                    instr <= mem_rdata[31:2];
                    state <= EXECUTE;
                end
            end
            state[EXECUTE_bit]: begin
                PC    <= PC_new;
                state <= needToWait ? WAIT_ALU_OR_MEM : FETCH_INSTR;
            end
            state[WAIT_ALU_OR_MEM_bit]: begin
                if (!aluBusy & !mem_rbusy & !mem_wbusy & !sobel_busy)
                    state <= FETCH_INSTR;
            end
            default: begin   // FETCH_INSTR
                state <= WAIT_INSTR;
            end
        endcase
    end

`ifdef BENCH
    initial begin
        cycles          = 0;
        registerFile[0] = 0;
    end
`endif

endmodule