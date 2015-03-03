parameter IRQ_VECADR = 16'hfffe;
parameter NMI_VECADR = 16'hfffa;

typedef struct packed{
    logic N;
    logic V;
    logic dummy;
    logic B;
    logic D;
    logic I;
    logic Z;
    logic C;
} status_t;

typedef struct packed{
    logic [7:0]  A;
    logic [7:0]  X;
    logic [7:0]  Y;
    logic [15:0] PC;
    logic [7:0]  SP;
    status_t     status;
} cpuReg_t;

typedef enum logic[7:0]{
/*
 *
 *  NONE             IMM              ZERO              ABS              ZEROX              ZEROY              ABSX              ABSY              INDX              INDY
 *
 */
                    LDA_IMM = 8'ha9, LDA_ZERO = 8'ha5, LDA_ABS = 8'had, LDA_ZEROX = 8'hb5,                    LDA_ABSX = 8'hbd, LDA_ABSY = 8'hb9, LDA_INDX = 8'ha1, LDA_INDY = 8'hb1,
                    LDX_IMM = 8'ha2, LDX_ZERO = 8'ha6, LDX_ABS = 8'hae,                    LDX_ZEROY = 8'hb6,                   LDX_ABSY = 8'hbe,
                    LDY_IMM = 8'ha0, LDY_ZERO = 8'ha4, LDY_ABS = 8'hac, LDY_ZEROX = 8'hb4,                    LDY_ABSX = 8'hbc,

                                     STA_ZERO = 8'h85, STA_ABS = 8'h8d, STA_ZEROX = 8'h95,                    STA_ABSX = 8'h9d, STA_ABSY = 8'h99, STA_INDX = 8'h81, STA_INDY = 8'h91,
                                     STX_ZERO = 8'h86, STX_ABS = 8'h8e,                    STX_ZEROY = 8'h96,
                                     STY_ZERO = 8'h84, STY_ABS = 8'h8c, STY_ZEROX = 8'h94,

    TXA = 8'h8a,
    TYA = 8'h98,
    TXS = 8'h9a,
    TAY = 8'ha8,
    TAX = 8'haa,
    TSX = 8'hba,

    PHP = 8'h08,
    PLP = 8'h28,
    PHA = 8'h48,
    PLA = 8'h68,

                    ADC_IMM = 8'h69,  ADC_ZERO = 8'h65, ADC_ABS = 8'h6d, ADC_ZEROX = 8'h75,                    ADC_ABSX = 8'h7d, ADC_ABSY = 8'h79, ADC_INDX = 8'h61, ADC_INDY = 8'h71,
                    SBC_IMM = 8'he9,  SBC_ZERO = 8'he5, SBC_ABS = 8'hed, SBC_ZEROX = 8'hf5,                    SBC_ABSX = 8'hfd, SBC_ABSY = 8'hf9, SBC_INDX = 8'he1, SBC_INDY = 8'hf1,
                    CPX_IMM = 8'he0,  CPX_ZERO = 8'he4, CPX_ABS = 8'hec,
                    CPY_IMM = 8'hc0,  CPY_ZERO = 8'hc4, CPY_ABS = 8'hcc,
                    CMP_IMM = 8'hc9,  CMP_ZERO = 8'hc5, CMP_ABS = 8'hcd, CMP_ZEROX = 8'hd5,                    CMP_ABSX = 8'hdd, CMP_ABSY = 8'hd9, CMP_INDX = 8'hc1, CMP_INDY = 8'hd1,

                    AND_IMM = 8'h29,  AND_ZERO = 8'h25, AND_ABS = 8'h2d, AND_ZEROX = 8'h35,                    AND_ABSX = 8'h3d, AND_ABSY = 8'h39, AND_INDX = 8'h21, AND_INDY = 8'h31,
                    EOR_IMM = 8'h49,  EOR_ZERO = 8'h45, EOR_ABS = 8'h4d, EOR_ZEROX = 8'h55,                    EOR_ABSX = 8'h5d, EOR_ABSY = 8'h59, EOR_INDX = 8'h41, EOR_INDY = 8'h51,
                    ORA_IMM = 8'h09,  ORA_ZERO = 8'h05, ORA_ABS = 8'h0d, ORA_ZEROX = 8'h15,                    ORA_ABSX = 8'h1d, ORA_ABSY = 8'h19, ORA_INDX = 8'h01, ORA_INDY = 8'h11,
                                      BIT_ZERO = 8'h24, BIT_ABS = 8'h2c,

    ASL = 8'h0a,                      ASL_ZERO = 8'h06, ASL_ABS = 8'h0e, ASL_ZEROX = 8'h16,                    ASL_ABSX = 8'h1e,
    LSR = 8'h4a,                      LSR_ZERO = 8'h46, LSR_ABS = 8'h4e, LSR_ZEROX = 8'h56,                    LSR_ABSX = 8'h5e,
    ROL = 8'h2a,                      ROL_ZERO = 8'h26, ROL_ABS = 8'h2e, ROL_ZEROX = 8'h36,                    ROL_ABSX = 8'h3e,
    ROR = 8'h6a,                      ROR_ZERO = 8'h66, ROR_ABS = 8'h6e, ROR_ZEROX = 8'h76,                    ROR_ABSX = 8'h7e,

    INX = 8'he8,
    INY = 8'hc8,
                                      INC_ZERO = 8'he6, INC_ABS = 8'hee, INC_ZEROX = 8'hf6,                    INC_ABSX = 8'hfe,
    DEX = 8'hca,
    DEY = 8'h88,
                                      DEC_ZERO = 8'hc6, DEC_ABS = 8'hce, DEC_ZEROX = 8'hd6,                    DEC_ABSX = 8'hde,

    CLC = 8'h18,
    CLI = 8'h58,
    CLV = 8'hb8,
    /*CLDはnesでは未実装*/
    SEC = 8'h38,
    SEI = 8'h78,
    /*SEDはnesでは未実装*/

    NOP = 8'hea,
    BRK = 8'h00,

                                                       JSR_ABS = 8'h20,
                                                       JMP_ABS = 8'h4c,                                                                                                               JMP_IND = 8'h6c,
    RTI = 8'h40,
    RTS = 8'h60,

    BPL = 8'h10,
    BMI = 8'h30,
    BVC = 8'h50,
    BVS = 8'h70,
    BCC = 8'h90,
    BCS = 8'hB0,
    BNE = 8'hD0,
    BEQ = 8'hF0
} opCode_t;