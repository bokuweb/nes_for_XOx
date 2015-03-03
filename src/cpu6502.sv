/**********************************************************************
* $Id$
*//**
* @file
* @brief
* @version  1.0
* @date
* @author
*
** Copyright(C) 2013, All rights reserved.
*
***********************************************************************/

module cpu6502(
    /* Input */
    input  logic clk,            /*! CPUクロック入力       */
    input  logic reset,          /*! リセット入力          */
    input  logic [7:0] din,      /*! データバス入力        */
    input  logic irq,            /*! IRQ入力               */
    input  logic nmi,            /*! NMI入力               */
    input  logic rdy,            /*! RDY入力               */
    /* Output */
    output logic we,             /*! ライトイネーブル出力  */
    output logic [15:0] adr,     /*! アドレスバス出力      */
    output logic [7:0] dout      /*! データバス出力        */
    );

    `include "defines.vh"
    `include "cpu6502.vh"

    state_t      currentState;
    state_t      nextState;
    opCode_t     opCode;
    cpuReg_t     cpuReg;

    logic [7:0]  opLand1;
    logic [7:0]  opLand2;
    logic [7:0]  writeData;
    logic [7:0]  indirectLowAdrres;
    logic [7:0]  newLowPC;
    logic        isNMI;
    logic        isIRQ;
    logic        isReadCycle;
    logic        isWriteCycle;
    logic [15:0] readAddress;
    logic [15:0] writeAddress;

    assign adr = (isReadCycle)  ? readAddress  :
                 (isWriteCycle) ? writeAddress :
                 cpuReg.PC;

    /*********************************************************************//**
    * @brief        ステート遷移回路
    *               クロックの立ち上がりにてcurrentStateの更新を行う
    **********************************************************************/
    always_ff@(posedge clk or posedge reset) begin
        if(reset) begin
            currentState <= #DELAY S0;
        end
        else begin
            currentState <= #DELAY nextState;
        end
    end

    /*********************************************************************//**
    * @brief        次ステート決定回路
    *               命令によって実行サイクル数を決定する
    **********************************************************************/
    always_comb begin
        case(currentState)
            /**
             * S0サイクル
             */
            S0 : begin
                nextState = S1;
            end
            /**
             * S1サイクル
             */
            S1 : begin
                case (opCode)
                    /**
                     *  サイクル数2の命令
                     *  次サイクルでS0に遷移
                     */
                    LDA_IMM, LDX_IMM, LDY_IMM, TAX, TAY, TSX, TXA, TXS, TYA,
                    ADC_IMM, AND_IMM, ASL, CMP_IMM, CPX_IMM, CPY_IMM, DEX, DEY,
                    EOR_IMM, INX, INY, LSR, ORA_IMM, ROL, ROR, SBC_IMM, BPL,
                    BMI, BVC, BVS, BCC, BCS, BNE, BEQ, CLC, CLI, CLV, SEC,
                    SEI, NOP : begin
                        nextState = S0;
                    end
                    /**
                     * 上記以外は次のステートへ遷移
                     */
                    default : begin
                        nextState = S2;
                    end
                endcase
            end
            /**
             * S2サイクル
             */
            S2 : begin
                case (opCode)
                    /**
                     *  サイクル数3の命令
                     *  次サイクルでS0に遷移
                     */
                    LDA_ZERO, LDX_ZERO, LDY_ZERO, STA_ZERO, STX_ZERO, STY_ZERO,
                    ADC_ZERO, AND_ZERO, BIT_ZERO, CMP_ZERO, CPX_ZERO, CPY_ZERO,
                    EOR_ZERO, ORA_ZERO, SBC_ZERO, PHA, PHP, JMP_ABS : begin
                        nextState = S0;
                    end
                    /**
                     * 上記以外は次のステートへ遷移
                     */
                    default : begin
                        nextState = S3;
                    end
                endcase
            end
            /**
             * S3サイクル
             */
            S3 : begin
                case (opCode)
                    /**
                     *  サイクル数4の命令
                     *  次サイクルでS0に遷移
                     */
                    LDA_ZEROX, LDA_ABS, LDA_ABSX, LDA_ABSY, LDX_ZEROY, LDX_ABS,
                    LDX_ABSY, LDY_ZEROX, LDY_ABS, LDY_ABSX, STA_ZEROX, STA_ABS,
                    STX_ZEROY, STX_ABS, STY_ZEROX, STX_ABS, ADC_ZEROX, ADC_ABS,
                    ADC_ABSX, ADC_ABSY, AND_ZEROX, AND_ABS, AND_ABSX, AND_ABSY,
                    BIT_ABS, CMP_ZEROX, CMP_ABS, CMP_ABSX, CMP_ABSY, CPX_ABS,
                    CPY_ABS, EOR_ZEROX, EOR_ABS, EOR_ABSX, EOR_ABSY, ORA_ZEROX,
                    ORA_ABS, ORA_ABSX, ORA_ABSY, SBC_ZEROX, SBC_ABS, SBC_ABSX,
                    SBC_ABSY, PLA, PLP : begin
                        nextState = S0;
                    end
                    /**
                     * 上記以外は次のステートへ遷移
                     */
                    default : begin
                        nextState = S4;
                    end
                endcase
            end
            /**
             * S4サイクル
             */
            S4 : begin
                case (opCode)
                    /**
                     *  サイクル数5の命令
                     *  次サイクルでS0に遷移
                     */
                    LDA_INDY, STA_ABSX, STA_ABSY, ADC_INDY, AND_INDY, ASL_ZERO,
                    CMP_INDY, DEC_ZERO, EOR_INDY, INC_ZERO, LSR_ZERO, ORA_INDY,
                    ROL_ZERO, ROR_ZERO, SBC_INDY, JMP_IND : begin
                        nextState = S0;
                    end
                    /**
                     * 上記以外は次のステートへ遷移
                     */
                    default : begin
                       nextState = S5;
                    end
                endcase
            end
            /**
             * S5サイクル
             */
            S5 : begin
                case (opCode)
                    /**
                     *  サイクル数6の命令
                     *  次サイクルでS0に遷移
                     */
                    LDA_INDX, STA_INDX, STA_INDY, ADC_INDX, AND_INDX,  ASL_ZEROX,
                    ASL_ABS, CMP_INDX, DEC_ZEROX, DEC_ABS, EOR_INDX, INC_ZEROX,
                    INC_ABS, LSR_ZEROX, LSR_ABS, ORA_INDX, ROL_ZEROX, ROL_ABS,
                    ROR_ZEROX, ROR_ABS, SBC_INDX, JSR_ABS, RTS, RTI : begin
                        nextState = S0;
                    end
                    /**
                     * 上記以外は次のステートへ遷移
                     */
                    default : begin
                        nextState = S6;
                    end
                endcase
            end
            /**
             * S6サイクル
             */
            S6 : begin
                nextState = S0;
            end
        endcase
    end

    /*********************************************************************//**
    * @brief        ステート処理部
    *               命令ごとに各サイクルで適当な処理を行う
    **********************************************************************/
    always_ff@(posedge clk or posedge reset) begin
        if(reset) begin
            cpuReg.A          <= #DELAY 8'h00;
            cpuReg.X          <= #DELAY 8'h00;
            cpuReg.Y          <= #DELAY 8'h00;
            cpuReg.PC         <= #DELAY 16'h8000;
            cpuReg.SP         <= #DELAY 8'hff;
            cpuReg.status     <= #DELAY 8'h24;
            opCode            <= #DELAY NOP;
            opLand1           <= #DELAY 8'h00;
            opLand2           <= #DELAY 8'h00;
            writeData         <= #DELAY 8'h00;
            indirectLowAdrres <= #DELAY 8'h00;
            newLowPC          <= #DELAY 8'h00;
            isNMI             <= #DELAY FALSE;
            isIRQ             <= #DELAY FALSE;
            dout              <= #DELAY 8'h00;
            we                <= #DELAY FALSE;
            isReadCycle       <= #DELAY FALSE;
            isWriteCycle      <= #DELAY FALSE;
            readAddress       <= #DELAY 16'h0000;
            writeAddress      <= #DELAY 16'h0000;
        end
        else begin
            case (currentState)
                /**
                 * S0サイクル
                 */
                S0 : begin
                    if(nmi) begin
                        isNMI <= #DELAY TRUE;
                    end
                    else if(irq && !cpuReg.status.I) begin
                        isIRQ <= #DELAY TRUE;
                    end
                    else begin
                        opCode   <= #DELAY (opCode_t'(din));
                        incrimentPC();
                    end
                end
                /**
                 * S1サイクル
                 */
                S1 : begin
                    if(isNMI || isIRQ) begin
                        cpuReg.status.B <= #DELAY FALSE;
                        cpuReg.status.I <= #DELAY TRUE;
                        write({8'h01, cpuReg.SP}, cpuReg.PC[15:8]);
                        cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                    end
                    else begin
                        case(opCode)
                            /**
                             *  Immediate命令
                             *  第１オペランドをデータとして命令を実行する
                             */
                            LDA_IMM, LDX_IMM, LDY_IMM : begin
                                load(opCode, din);
                                incrimentPC();
                            end
                            CMP_IMM, CPX_IMM, CPY_IMM : begin
                                compare(opCode, din);
                                incrimentPC();
                            end
                            ADC_IMM, AND_IMM, EOR_IMM, ORA_IMM, SBC_IMM : begin
                                operate(opCode, din);
                                incrimentPC();
                            end
                            /**
                             *  Implied命令
                             */
                            ASL, LSR, DEX, DEY, INX, INY, ROL, ROR : begin
                                operate(opCode, 0);
                            end
                            TAX, TAY, TSX, TXA, TXS, TYA : begin
                                transfer(opCode);
                            end
                            PHA : begin
                                write({8'h01, cpuReg.SP}, cpuReg.A);
                            end
                            PHP : begin
                                write({8'h01, cpuReg.SP}, cpuReg.status);
                            end
                            PLA, PLP : begin
                                /* 何もしない */
                            end
                            SEC, SEI : begin
                                set(opCode);
                            end
                            CLC, CLI, CLV : begin
                                clear(opCode);
                            end
                            BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ : begin
                                branch(opCode, din);
                            end
                            /**
                             *  ZERO命令(ロード,比較,演算)
                             *  上位アドレスは0x00とし第１オペランドを下位アドレスとする領域
                             *  にリードを開始する
                             */
                            LDA_ZERO, LDX_ZERO, LDY_ZERO, ADC_ZERO, AND_ZERO, BIT_ZERO,
                            CMP_ZERO, CPX_ZERO, CPY_ZERO, EOR_ZERO, ORA_ZERO, SBC_ZERO,
                            ASL_ZERO, LSR_ZERO, INC_ZERO, DEC_ZERO, ROL_ZERO, ROR_ZERO : begin
                                read({8'h00, din});
                                incrimentPC();
                            end
                            /**
                             *  ZERO命令(ストア)
                             *  上位アドレスは0x00とし第１オペランドを下位アドレスとする領域
                             *  にライトを開始する
                             */
                            STA_ZERO, STX_ZERO, STY_ZERO : begin
                                store(opCode, {8'h00, din});
                            end
                            /**
                             *  INDY命令
                             *  上位アドレスは0x00とし第１オペランドを下位アドレスとする領域
                             *  にリードを開始する
                             */
                            LDA_INDY, CMP_INDY, ADC_INDY, AND_INDY, EOR_INDY, ORA_INDY,
                            SBC_INDY, STA_INDY : begin
                                read({8'h00, din});
                                incrimentPC();
                            end
                            RTS, RTI : begin
                                /* 何もしない? */
                            end
                            BRK : begin
                                cpuReg.status.B <= #DELAY TRUE;
                                cpuReg.status.I <= #DELAY TRUE;
                                write({8'h01, cpuReg.SP}, cpuReg.PC[15:8]);
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            /**
                             *  その他命令
                             */
                             default : begin
                                incrimentPC();
                                opLand1 <= #DELAY din;
                            end
                        endcase
                    end
                end
                /**
                 * S2サイクル
                 */
                S2 : begin
                    if(isNMI || isIRQ) begin
                        write({8'h01, cpuReg.SP}, cpuReg.PC[7:0]);
                        cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                    end
                    else begin
                        case(opCode)
                            /**
                             *  Implied命令
                             */
                            PHA, PHP : begin
                                writeStop();
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            PLA, PLP : begin
                                read({8'h01, (cpuReg.SP + 1'b1)});
                                cpuReg.SP <= #DELAY cpuReg.SP + 1'b1;
                            end
                            /**
                             *  ZERO命令(ロード,比較,演算)
                             *  リード動作を停止し、リードデータをもとに演算等を行う
                             */
                            LDA_ZERO, LDX_ZERO, LDY_ZERO : begin
                                readStop();
                                load(opCode, din);
                            end
                            CMP_ZERO, CPX_ZERO, CPY_ZERO : begin
                                readStop();
                                compare(opCode, din);
                            end
                            ADC_ZERO, AND_ZERO, BIT_ZERO, EOR_ZERO, ORA_ZERO, SBC_ZERO,
                            ASL_ZERO, LSR_ZERO, DEC_ZERO, INC_ZERO, ROL_ZERO, ROR_ZERO : begin
                                readStop();
                                operate(opCode, din);
                            end
                            /**
                             *  ZERO命令(ストア)
                             *  ライトの完了
                             */
                            STA_ZERO, STX_ZERO, STY_ZERO : begin
                                writeStop();
                            end
                            /**
                             *  ZEROX命令(ロード,比較,演算)
                             *  上位アドレスは0x00とし(第１オペランド + Xレジスタ)を下位
                             *  アドレスとする領域にリードを開始する
                             */
                            LDA_ZEROX, LDY_ZEROX, ADC_ZEROX, AND_ZEROX, CMP_ZEROX,
                            EOR_ZEROX, ORA_ZEROX, SBC_ZEROX, ASL_ZEROX, LSR_ZEROX,
                            DEC_ZEROX, INC_ZEROX, ROL_ZEROX, ROR_ZEROX : begin
                                read({8'h00, (opLand1 + cpuReg.X)});
                            end
                            /**
                             *  ZEROX命令(ストア)
                             *  上位アドレスは0x00とし(第１オペランド + Xレジスタ)を下位
                             *  アドレスとする領域にライトを開始する(加算による繰り上がりは無視)
                             */
                            STA_ZEROX, STY_ZEROX : begin
                                store(opCode, {8'h00, (opLand1 + cpuReg.X)});
                            end
                            /**
                             *  ZEROY命令(ロード)
                             *  上位アドレスは0x00とし(第１オペランド + Yレジスタ)を下位
                             *  アドレスとする領域にリードを開始する(加算による繰り上がりは無視)
                             */
                            LDX_ZEROY : begin
                                read({8'h00, (opLand1 + cpuReg.Y)});
                            end
                            /**
                             *  ZEROY命令(ストア)
                             *  上位アドレスは0x00とし(第１オペランド + Yレジスタ)を下位
                             *  アドレスとする領域にライトを開始する(加算による繰り上がりは無視)
                             */
                            STX_ZEROY : begin
                                store(opCode, {8'h00, (opLand1 + cpuReg.Y)});
                            end
                            /**
                             *  ABS命令(ロード,比較,演算)
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  する領域へリードを開始する
                             */
                            LDA_ABS, LDY_ABS, ADC_ABS, AND_ABS, BIT_ABS, CMP_ABS,
                            CPX_ABS, CPY_ABS, EOR_ABS, ORA_ABS, SBC_ABS, ASL_ABS,
                            LSR_ABS, DEC_ABS, INC_ABS, ROL_ABS, ROR_ABS : begin
                                read({din, opLand1});
                                incrimentPC();
                            end
                            /**
                             *  ABS命令(ストア)
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  する領域へストアを開始する
                             */
                            STA_ABS, STX_ABS, STY_ABS : begin
                                store(opCode, {din, opLand1});
                                incrimentPC();
                            end
                            /**
                             *  ABS命令(ジャンプ)
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  するアドレスをPCにセットする
                             */
                            JMP_ABS : begin
                                setPC({din, opLand1});
                            end
                            /**
                             *  ABSX命令(ロード,比較,演算)
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  するアドレスにXレジスタの値を加算した領域へリードを開始する
                             */
                            LDA_ABSX, LDY_ABSX, ADC_ABSX, AND_ABSX, CMP_ABSX, EOR_ABSX,
                            ORA_ABSX, SBC_ABSX : begin
                                read({din, opLand1} + cpuReg.X);
                                incrimentPC();
                            end
                            /**
                             *  ABSY命令(ロード,比較,演算)
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  するアドレスにYレジスタの値を加算した領域へリードを開始する
                             */
                            LDA_ABSY, LDX_ABSY, ADC_ABSY, AND_ABSY, CMP_ABSY, EOR_ABSY,
                            ORA_ABSY, SBC_ABSY : begin
                                read({din, opLand1} + cpuReg.Y);
                                incrimentPC();
                            end
                            /**
                             *  IND命令
                             *  第１オペランドを下位バイト，第２オペランドを上位バイトと
                             *  する領域へリードを開始する
                             */
                            JMP_IND : begin
                                read({din, opLand1});
                                incrimentPC();
                            end
                            /**
                             *  INDX命令
                             *  第1オペランドの示すアドレスにXレジスタを加算した領域から
                             *  1バイト目をリードする(加算による繰り上がりは無視)
                             */
                            LDA_INDX, CMP_INDX, ADC_INDX, AND_INDX, EOR_INDX, ORA_INDX,
                            SBC_INDX, STA_INDX : begin
                                read({8'h00, (opLand1 + cpuReg.X)});
                            end
                            /**
                             *  INDY命令
                             *  第1オペランドの示すアドレスから2バイト目をリードする
                             */
                            LDA_INDY, CMP_INDY, ADC_INDY, AND_INDY, EOR_INDY, ORA_INDY,
                            SBC_INDY, STA_INDY : begin
                                read({8'h00, opLand1} + 1'b1);
                                indirectLowAdrres <= #DELAY din;
                            end
                            RTS : begin
                                /* 何もしない? */
                            end
                            RTI : begin
                                cpuReg.SP     <= #DELAY cpuReg.SP + 1'b1;
                                read({8'h01, cpuReg.SP} + 1'b1);
                            end
                            JSR_ABS : begin
                                write({8'h01, cpuReg.SP}, cpuReg.PC[15:8]);
                            end
                            BRK : begin
                                write({8'h01, cpuReg.SP}, cpuReg.PC[7:0] + 1'b1);  /* BRK命令のアドレス + 2番地がプッシュされるらしい
                                                                                      オペランドフェッチ時にインクリメントされている
                                                                                      ため更に+1する
                                                                                    */
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            /**
                             *  その他の命令
                             */
                            default : begin
                                incrimentPC();
                                opLand2 <= #DELAY din;
                            end
                        endcase
                    end
                end
                /**
                 * S3サイクル
                 */
                S3 : begin
                    if(isNMI || isIRQ) begin
                        write({8'h01, cpuReg.SP}, cpuReg.status);
                        cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                    end
                    else begin
                        case(opCode)
                            /**
                             *  Implied命令
                             */
                            PLA : begin
                                readStop();
                                cpuReg.A <= din;
                            end
                            PLP : begin
                                readStop();
                                cpuReg.status <= din;
                            end
                            /**
                             *  ZERO命令(メモリにライトが必要な命令)
                             *  上位アドレスは0x00とし第１オペランドを下位アドレスとする領域
                             *  に計算結果をライトを開始する
                             */
                            ASL_ZERO, LSR_ZERO, DEC_ZERO, INC_ZERO, ROL_ZERO, ROR_ZERO : begin
                                write({8'h00, opLand1}, writeData);
                            end
                            /**
                             *  ZEROX, ZEROY, ABS, ABSX, ABSY命令
                             *  リードを終了し、演算を行う
                             */
                            LDA_ABS, LDY_ABS, LDA_ABSX, LDY_ABSX, LDA_ABSY, LDX_ABSY,
                            LDA_ZEROX, LDY_ZEROX, LDX_ZEROY : begin
                                readStop();
                                load(opCode, din);
                            end
                            CMP_ABS, CPX_ABS, CPY_ABS, CMP_ABSX, CMP_ABSY : begin
                                readStop();
                                compare(opCode, din);
                            end
                            ADC_ABSX, AND_ABSX, EOR_ABSX, ORA_ABSX, SBC_ABSX,
                            ADC_ABSY, AND_ABSY, EOR_ABSY, ORA_ABSY, SBC_ABSY,
                            ADC_ABS, AND_ABS, EOR_ABS, ORA_ABS, SBC_ABS, BIT_ABS,
                            ASL_ABS, LSR_ABS, DEC_ABS,  INC_ABS,  ROL_ABS, ROR_ABS,
                            ADC_ZEROX, AND_ZEROX, EOR_ZEROX, ORA_ZEROX, SBC_ZEROX, CMP_ZEROX,
                            ASL_ZEROX, LSR_ZEROX, DEC_ZEROX, INC_ZEROX, ROR_ZEROX, ROL_ZEROX : begin
                                readStop();
                                operate(opCode, din);
                            end
                            /**
                             *  ZEROX, ZEROY, ABS(ストア)
                             *  ライトの完了
                             */
                            STA_ABS, STX_ABS, STY_ABS , STX_ZEROY, STA_ZEROX, STY_ZEROX : begin
                                writeStop();
                            end
                            /**
                             *  ABSX(ストア)
                             *  (絶対アドレス + Xレジスタ)領域へリードを行う
                             */
                            ASL_ABSX, LSR_ABSX, DEC_ABSX, INC_ABSX, ROL_ABSX, ROR_ABSX : begin
                                read({opLand2, opLand1} + cpuReg.X);
                            end
                            /**
                             *  ABSX(ストア)
                             *  (絶対アドレス + Xレジスタ)領域へライトを行う
                             */
                            STA_ABSX : begin
                                store(opCode, {opLand2, opLand1} + cpuReg.X);
                            end
                            /**
                             *  ABSY(ストア)
                             *  (絶対アドレス + Yレジスタ)領域へライトを行う
                             */
                            STA_ABSY : begin
                                store(opCode, {opLand2, opLand1} + cpuReg.Y);
                            end
                            /**
                             *  IND命令
                             *  第1、第2オペランドの示すアドレスから2バイト目をリードする
                             */
                            JMP_IND : begin
                                indirectLowAdrres <= #DELAY din;
                                read({opLand2, opLand1} + 1'b1);
                            end
                            /**
                             *  INDX命令
                             *  第1オペランドの示すアドレスにXレジスタを加算した領域から
                             *  2バイト目をリードする
                             */
                            LDA_INDX, CMP_INDX, ADC_INDX, AND_INDX, EOR_INDX, ORA_INDX,
                            SBC_INDX, STA_INDX: begin
                                indirectLowAdrres <= #DELAY din;
                                read({8'h00, (opLand1 + cpuReg.X)} + 1'b1);
                            end
                            /**
                             *  INDY命令
                             *  第1オペランドの示す実効アドレスからリードした２バイトに
                             *  Ｙレジスタを加算した領域にリードを開始する
                             */
                            LDA_INDY, CMP_INDY, ADC_INDY, AND_INDY, EOR_INDY, ORA_INDY,
                            SBC_INDY, STA_INDY : begin
                                read({din, indirectLowAdrres} + cpuReg.Y);
                            end
                            RTI : begin
                                cpuReg.status <= #DELAY din;
                                cpuReg.SP     <= #DELAY cpuReg.SP + 1'b1;
                                read({8'h01, cpuReg.SP} + 1'b1);
                            end
                            RTS : begin
                                cpuReg.SP     <= #DELAY cpuReg.SP + 1'b1;
                                read({8'h01, cpuReg.SP} + 1'b1);
                            end
                            JSR_ABS : begin
                                write({8'h01, cpuReg.SP}, cpuReg.PC[15:8]);
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            BRK : begin
                                write({8'h01, cpuReg.SP}, cpuReg.status);
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            default : /* default */;
                        endcase
                    end
                end
                /**
                 * S4サイクル
                 */
                S4 : begin
                    if(isNMI) begin
                        writeStop();
                        read(NMI_VECADR);
                    end
                    else if(isIRQ) begin
                        writeStop();
                        read(IRQ_VECADR);
                    end
                    else begin
                        case(opCode)
                            /**
                             *  ZERO命令(メモリにライトが必要な命令)
                             *  ライト(メモリへの書き込み)完了
                             */
                            ASL_ZERO, LSR_ZERO, DEC_ZERO, INC_ZERO, ROL_ZERO, ROR_ZERO : begin
                                writeStop();
                            end
                            /**
                             *  ZEROX(メモリにライトが必要な命令)
                             *  メモリへのライトを開始
                             */
                            ASL_ZEROX, LSR_ZEROX,  DEC_ZEROX, INC_ZEROX, ROL_ZEROX, ROR_ZEROX : begin
                                write({8'h00, (opLand1 + cpuReg.X)}, writeData);
                            end
                            /**
                             *  ABS(メモリにライトが必要な命令)
                             *  メモリへのライトを開始
                             */
                            ASL_ABS, LSR_ABS, DEC_ABS, INC_ABS, ROL_ABS, ROR_ABS : begin
                                write({opLand2, opLand1}, writeData);
                            end
                            /**
                             *  ABSX、ABSY命令(メモリにライトが必要な命令)
                             *  ライト(メモリへの書き込み)完了
                             */
                            STA_ABSX, STA_ABSY : begin
                                writeStop();
                            end
                            ASL_ABSX, LSR_ABSX, DEC_ABSX, INC_ABSX, ROL_ABSX, ROR_ABSX : begin
                                readStop();
                                operate(opCode, din);
                            end
                            /**
                             *  IND命令
                             *  第1,第2オペランドの示す領域からリードした2バイトのアドレスを
                             *  PCにセットする
                             */
                            JMP_IND : begin
                                readStop();
                                setPC({din, indirectLowAdrres});
                            end
                            /**
                             *  INDX命令
                             */
                            LDA_INDX, CMP_INDX, ADC_INDX, AND_INDX, EOR_INDX, ORA_INDX,
                            SBC_INDX : begin
                                read({din, indirectLowAdrres});
                            end
                            STA_INDX : begin
                                readStop();
                                write({din, indirectLowAdrres}, cpuReg.A);
                            end
                            /**
                             *  INDY命令
                             */
                            LDA_INDY : begin
                                readStop();
                                load(opCode, din);
                            end
                            CMP_INDY : begin
                                readStop();
                                compare(opCode, din);
                            end
                            ADC_INDY, AND_INDY, EOR_INDY, ORA_INDY, SBC_INDY : begin
                                readStop();
                                operate(opCode, din);
                            end
                            STA_INDY : begin
                                readStop();
                                write({din, indirectLowAdrres} + cpuReg.Y, cpuReg.A);
                            end

                            RTS, RTI : begin
                                newLowPC  <= din;
                                cpuReg.SP <= #DELAY cpuReg.SP + 1'b1;
                                read({8'h01, cpuReg.SP} + 1'b1);
                            end

                            JSR_ABS : begin
                                write({8'h01, cpuReg.SP}, cpuReg.PC[7:0]); /*
                                                                              実機ではJSR命令の第1オペランドを示すアドレスが
                                                                              スタックされ、RTSでインクリメントされるがここでは
                                                                              JSRの次の命令アドレスをスタックしておく。すでにPC
                                                                              はインクリメントすみのためPC[7:0]をセット
                                                                            */
                                cpuReg.SP <= #DELAY cpuReg.SP - 1'b1;
                            end
                            BRK : begin
                                writeStop();
                                read(IRQ_VECADR);
                            end
                            default : /* default */;
                        endcase
                    end
                end
                /**
                 * S5サイクル
                 */
                S5 : begin
                    if(isNMI) begin
                        newLowPC <= #DELAY din;
                        read(NMI_VECADR + 1'b1);
                    end
                    else if(isIRQ) begin
                        newLowPC <= #DELAY din;
                        read(IRQ_VECADR + 1'b1);
                    end
                    else begin
                        case (opCode)
                            /**
                             *  ZEROX、ABS命令(メモリにライトが必要な命令)
                             */
                            ASL_ZEROX, LSR_ZEROX,  DEC_ZEROX, INC_ZEROX, ROL_ZEROX, ROR_ZEROX,
                            ASL_ABS, LSR_ABS, DEC_ABS, INC_ABS, ROL_ABS, ROR_ABS : begin
                                writeStop();
                            end
                            ASL_ABSX, LSR_ABSX, DEC_ABSX, INC_ABSX, ROL_ABSX, ROR_ABSX : begin
                                write({opLand2, opLand1} + cpuReg.X, writeData);
                            end
                            /**
                             *  INDX命令
                             */
                            LDA_INDX : begin
                                readStop();
                                load(opCode, din);
                            end
                            CMP_INDX : begin
                                readStop();
                                compare(opCode, din);
                            end
                            STA_INDX : begin
                                writeStop();
                            end
                            ADC_INDX, AND_INDX, EOR_INDX, ORA_INDX, SBC_INDX : begin
                                readStop();
                                operate(opCode, din);
                            end
                            /**
                             *  INDY命令
                             */
                            STA_INDY : begin
                                writeStop();
                            end

                            RTS, RTI : begin
                                readStop();
                                setPC({din, newLowPC});
                            end
                            JSR_ABS : begin
                                writeStop();
                                setPC({opLand2, opLand1});
                            end
                            BRK : begin
                                newLowPC <= #DELAY din;
                                read(IRQ_VECADR + 1'b1);
                            end
                        endcase
                    end
                end
                /**
                 * S6サイクル
                 */
                S6 : begin
                    if(isNMI || isIRQ) begin
                        readStop();
                        setPC({din, newLowPC});
                        isIRQ <= #DELAY FALSE;
                        isNMI <= #DELAY FALSE;
                    end
                    else begin
                        case (opCode)
                            ASL_ABSX, LSR_ABSX, DEC_ABSX, INC_ABSX, ROL_ABSX, ROR_ABSX : begin
                                writeStop();
                            end
                            BRK : begin
                                readStop();
                                setPC({din, newLowPC});
                            end
                            default : /* default */;
                        endcase
                    end
                end
                default : /* default */;
            endcase
        end
    end
    /*********************************************************************//**
    * @brief
    * @param[in]    None
    * @return       None
    **********************************************************************/
    task writeStop;
        we           <= #DELAY FALSE;
        isWriteCycle <= #DELAY FALSE;
    endtask : writeStop

    /*********************************************************************//**
    * @brief
    * @param[in]
    * @return       None
    **********************************************************************/
    task write(input [15:0] adr, input[7:0] data);
        isWriteCycle <= #DELAY TRUE;
        writeAddress <= #DELAY adr;
        dout         <= #DELAY data;
        we           <= #DELAY TRUE;
    endtask : write

    /*********************************************************************//**
    * @brief
    * @param[in]    None
    * @return       None
    **********************************************************************/
    task readStop;
        isReadCycle <= #DELAY FALSE;
    endtask : readStop

    /*********************************************************************//**
    * @brief
    * @param[in]
    * @return       None
    **********************************************************************/
    task read(input [15:0] adr);
        isReadCycle <= #DELAY TRUE;
        readAddress <= #DELAY adr;
    endtask : read

    /*********************************************************************//**
    * @brief
    * @param[in]
    * @return       None
    **********************************************************************/
    task incrimentPC();
        cpuReg.PC <= #DELAY cpuReg.PC + 1'b1;
    endtask : incrimentPC

    /*********************************************************************//**
    * @brief        PC更新タスク
    * @param[in]    addAdr 現在のPCに加算するアドレス
    * 　　　　　　　 - 最上位bit[7]が1の場合は負の値とし減算を行う
    * @return       None
    **********************************************************************/
    task addPC(input [7:0] addAdr);
        if(addAdr[7]) begin
            cpuReg.PC <= #DELAY cpuReg.PC - {9'h00, (~addAdr[6:0])};
        end
        else begin
            cpuReg.PC <= #DELAY cpuReg.PC + addAdr[6:0] + 1'b1;
        end
    endtask : addPC

    /*********************************************************************//**
    * @brief        PCセットタスク
    * @param[in]    adr 現在のPCにセットするアドレス
    * @return       None
    **********************************************************************/
    task setPC(input [15:0] address);
        cpuReg.PC <= #DELAY address;
    endtask : setPC

    /*********************************************************************//**
    * @brief        ロード命令実行タスク
    * @param[in]    code オペコード
    * @param[in]    data ロードデータ　　　　　　　
    * @return       None
    **********************************************************************/
    task load(input [7:0] code, input [7:0] data);
        case (code)
            LDA_IMM, LDA_ABS, LDA_ABSX, LDA_ABSY, LDA_ZERO, LDA_ZEROX,
            LDA_INDX, LDA_INDY : begin
                cpuReg.A <= #DELAY data;
            end
            LDX_IMM, LDX_ABS, LDX_ABSY, LDX_ZERO, LDX_ZEROY : begin
                cpuReg.X <= #DELAY data;
            end
            LDY_IMM, LDY_ABS, LDY_ABSX, LDY_ZERO, LDY_ZEROX : begin
                cpuReg.Y <= #DELAY data;
            end
        endcase
        cpuReg.status.N <= #DELAY data[7];
        cpuReg.status.Z <= #DELAY (data == 8'h00);
    endtask : load

    /*********************************************************************//**
    * @brief        転送命令実行タスク
    * @param[in]    code オペコード
    * @return       None
    **********************************************************************/
    task transfer;
        input [7:0] code;
        begin
            case (code)
                TAX : begin
                    cpuReg.X        <= #DELAY cpuReg.A;
                    cpuReg.status.N <= #DELAY cpuReg.A[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.A == 8'h00);
                end
                TAY : begin
                    cpuReg.Y        <= #DELAY cpuReg.A;
                    cpuReg.status.N <= #DELAY cpuReg.A[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.A == 8'h00);
                end
                TSX : begin
                    cpuReg.X        <= #DELAY cpuReg.SP;
                    cpuReg.status.N <= #DELAY cpuReg.SP[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.SP == 8'h00);
                end
                TXA : begin
                    cpuReg.A  <= #DELAY cpuReg.X;
                    cpuReg.status.N <= #DELAY cpuReg.X[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.X == 8'h00);
                end
                TXS : begin
                    cpuReg.SP <= #DELAY cpuReg.X;
                    cpuReg.status.N <= #DELAY cpuReg.X[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.X == 8'h00);
                end
                TYA : begin
                    cpuReg.A  <= #DELAY cpuReg.Y;
                    cpuReg.status.N <= #DELAY cpuReg.Y[7];
                    cpuReg.status.Z <= #DELAY (cpuReg.Y == 8'h00);
                end
            endcase
        end
    endtask : transfer

    /*********************************************************************//**
    * @brief        ストア命令実行タスク
    * @param[in]    code オペコード
    * @param[in]    adr  ストア先アドレス
    * @return       None
    **********************************************************************/
    task store(input [7:0] code, input [15:0] address);
        case(code)
            STA_ZERO, STA_ZEROX, STA_ABS, STA_ABSX, STA_ABSY : begin
                write(address, cpuReg.A);
            end
            STX_ZERO, STX_ZEROY, STX_ABS : begin
                write(address, cpuReg.X);
            end
            STY_ZERO, STY_ZEROX, STY_ABS : begin
                write(address, cpuReg.Y);
            end
        endcase
    endtask : store

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task operate(input [7:0] code, input [7:0] data);
        case(code)
            ADC_IMM, ADC_ZERO, ADC_ZEROX, ADC_ABS, ADC_ABSX, ADC_ABSY,
            ADC_INDX, ADC_INDY : begin
                add(data);
            end
            AND_IMM, AND_ZERO, AND_ZEROX, AND_ABS, AND_ABSX, AND_ABSY,
            AND_INDX, AND_INDY : begin
                anda(data);
            end
            EOR_IMM, EOR_ZERO, EOR_ZEROX, EOR_ABS, EOR_ABSX, EOR_ABSY,
            EOR_INDX, EOR_INDY : begin
                xora(data);
            end
            ORA_IMM, ORA_ZERO, ORA_ZEROX, ORA_ABS, ORA_ABSX, ORA_ABSY,
            ORA_INDX, ORA_INDY : begin
                ora(data);
            end
            SBC_IMM, SBC_ZERO, SBC_ZEROX, SBC_ABS, SBC_ABSX, SBC_ABSY,
            SBC_INDX, SBC_INDY : begin
                sub(data);
            end
            ASL, ASL_ZERO, LSR, LSR_ZERO, ASL_ABSX, LSR_ABSX : begin
                shift(code, data);
            end
            DEX, DEY, DEC_ZERO, DEC_ABSX : begin
                decriment(code, data);
            end
            INX, INY, INC_ZERO, INC_ABSX : begin
                incriment(code, data);
            end
            ROL, ROL_ZERO, ROR, ROR_ZERO, ROL_ABSX, ROR_ABSX : begin
                rotate(code, data);
            end
            BIT_ABS, BIT_ZERO : begin
                bita(data);
            end
        endcase
    endtask : operate

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task compare(input [7:0] code, input[7:0] data);
        logic[7:0] regValue;

        case (code)
            CMP_IMM, CMP_ZERO, CMP_ZEROX, CMP_ABS, CMP_ABSX, CMP_ABSY,
            CMP_INDX, CMP_INDY : begin
                regValue = cpuReg.A;
            end
            CPX_IMM, CPX_ZERO, CPX_ABS : begin
                regValue = cpuReg.X;
            end
            CPY_IMM, CPY_ZERO, CPY_ABS : begin
                regValue = cpuReg.Y;
            end
            default : regValue = 0;
        endcase

        if(regValue > data) begin
            cpuReg.status.C <= #DELAY TRUE;
        end
        else if(regValue == data) begin
            cpuReg.status.Z <= #DELAY TRUE;
            cpuReg.status.C <= #DELAY TRUE;
        end
        else begin
            cpuReg.status.N <= #DELAY TRUE;
            cpuReg.status.C <= #DELAY FALSE;
        end
    endtask : compare

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task clear(input [7:0] code);
        case(code)
            CLC : cpuReg.status.C <= #DELAY 1'b0;
            CLI : cpuReg.status.I <= #DELAY 1'b0;
            CLV : cpuReg.status.V <= #DELAY 1'b0;
        endcase
    endtask : clear

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task bita(input [7:0] data);
        cpuReg.status.Z <= #DELAY ((cpuReg.A & data) ? FALSE : TRUE);
        cpuReg.status.N <= #DELAY data[7];
        cpuReg.status.V <= #DELAY data[6];
    endtask : bita

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task set(input [7:0] code);
        case(code)
            SEC : cpuReg.status.C <= #DELAY 1'b1;
            SEI : cpuReg.status.I <= #DELAY 1'b1;
        endcase
    endtask : set

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task branch(input [7:0] code, input [7:0] addAdr);
        case(code)
            BPL : begin
                if(!cpuReg.status.N) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BMI : begin
                if(cpuReg.status.N) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BVC : begin
                if(!cpuReg.status.V) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BVS : begin
                if(cpuReg.status.V) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BCC : begin
                if(!cpuReg.status.C) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BCS : begin
                if(cpuReg.status.C) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BNE : begin
                if(!cpuReg.status.Z) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
            BEQ : begin
                if(cpuReg.status.Z) begin
                    addPC(addAdr);
                end
                else begin
                    incrimentPC();
                end
            end
        endcase
    endtask : branch

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task anda(input [7:0] andData);
        logic [7:0] result;
        result = cpuReg.A & andData;

        cpuReg.A        <= #DELAY result;
        cpuReg.status.N <= #DELAY result[7];
        cpuReg.status.Z <= #DELAY (result == 0);
        cpuReg.status.Z <= #DELAY (result == 0);
    endtask : anda

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task ora(input [7:0] orData);
        logic [7:0] result;
        result = cpuReg.A & orData;

        cpuReg.A        <= #DELAY result;
        cpuReg.status.N <= #DELAY result[7];
        cpuReg.status.Z <= #DELAY (result == 0);
    endtask : ora

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task xora(input [7:0] eorData);
        logic [7:0] result;
        result = cpuReg.A ^ eorData;

        cpuReg.A        <= #DELAY result;
        cpuReg.status.N <= #DELAY result[7];
        cpuReg.status.Z <= #DELAY (result == 0);
    endtask : xora

    /*********************************************************************//**
    * @brief        シフト命令を実行する
    * @param[in]    code オペコード
    * @param[in]    data シフト対象メモリデータ　　　　　　　
    * @return       None
    **********************************************************************/
    task shift(input [7:0] code, input [7:0] data);
        case (code)
            ASL      : begin
                cpuReg.A        <= #DELAY {cpuReg.A[6:0], 1'b0};
                cpuReg.status.N <= #DELAY cpuReg.A[6];
                cpuReg.status.Z <= #DELAY (cpuReg.A[6:0] == 7'h00);
                cpuReg.status.C <= #DELAY cpuReg.A[7];
            end
            ASL_ZERO, ASL_ZEROX, ASL_ABS, ASL_ABSX : begin
                writeData       <= #DELAY {data[6:0], 1'b0};
                cpuReg.status.N <= #DELAY data[6];
                cpuReg.status.Z <= #DELAY (data[6:0] == 7'h00);
                cpuReg.status.C <= #DELAY data[7];
            end
            LSR      : begin
                cpuReg.A        <= #DELAY {1'b0, cpuReg.A[7:1]};
                cpuReg.status.N <= #DELAY FALSE;
                cpuReg.status.Z <= #DELAY (cpuReg.A[7:1] == 7'h00);
                cpuReg.status.C <= #DELAY cpuReg.A[0];
            end
            LSR_ZERO, LSR_ZEROX, LSR_ABS, LSR_ABSX : begin
                writeData       <= #DELAY {1'b0, data[7:1]};
                cpuReg.status.N <= #DELAY FALSE;
                cpuReg.status.Z <= #DELAY (data[7:1] == 7'h00);
                cpuReg.status.C <= #DELAY data[0];
            end
           default : /* default */;
        endcase
    endtask : shift

    /*********************************************************************//**
    * @brief        ローテーション命令を実行する
    * @param[in]    code オペコード
    * @param[in]    data ローテーション対象メモリデータ　　　　　　　
    * @return       None
    **********************************************************************/
    task rotate(input [7:0] code, input [7:0] data);
        case (code)
            ROL : begin
                cpuReg.A        <= #DELAY {cpuReg.A[6:0], cpuReg.status.C};
                cpuReg.status.N <= #DELAY cpuReg.A[6];
                cpuReg.status.Z <= #DELAY ({cpuReg.A[6:0], cpuReg.status.C} == 8'h00);
                cpuReg.status.C <= #DELAY cpuReg.A[7];
            end
            ROL_ZERO, ROL_ZEROX, ROL_ABS, ROL_ABSX : begin
                writeData       <= #DELAY {data[6:0], cpuReg.status.C};
                cpuReg.status.N <= #DELAY data[6];
                cpuReg.status.Z <= #DELAY ({data[6:0], cpuReg.status.C} == 8'h00);
                cpuReg.status.C <= #DELAY data[7];
            end
            ROR : begin
                cpuReg.A        <= #DELAY {cpuReg.status.C, cpuReg.A[7:1]};
                cpuReg.status.N <= #DELAY cpuReg.status.C;
                cpuReg.status.Z <= #DELAY ({cpuReg.status.C, cpuReg.A[7:1]} == 8'h00);
                cpuReg.status.C <= #DELAY cpuReg.A[0];
            end
            ROR_ZERO, ROR_ZEROX, ROR_ABS, ROR_ABSX : begin
                writeData       <= #DELAY {cpuReg.status.C, data[7:1]};
                cpuReg.status.N <= #DELAY cpuReg.status.C;
                cpuReg.status.Z <= #DELAY ({cpuReg.status.C, data[7:1]} == 8'h00);
                cpuReg.status.C <= #DELAY data[0];
            end
            default : /* default */;
        endcase
    endtask : rotate

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task add(input [7:0] addValue);
        logic [8:0] result;
        result = cpuReg.A + addValue + cpuReg.status.C;

        cpuReg.A        <= #DELAY result;
        cpuReg.status.N <= #DELAY result[7];
        cpuReg.status.V <= #DELAY ((result[7] == 1) && (cpuReg.A[7] == 0));
        cpuReg.status.Z <= #DELAY result[7:0] == 0;
        cpuReg.status.C <= #DELAY result[8];
    endtask : add

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task sub(input [7:0] subValue);
        logic [8:0] result;
        result = cpuReg.A - subValue - !cpuReg.status.C;

        cpuReg.A        <= #DELAY result;
        cpuReg.status.N <= #DELAY result[7];
        cpuReg.status.V <= #DELAY ((result[7] == 1) && (cpuReg.A[7] == 0));
        cpuReg.status.Z <= #DELAY (result[7:0] == 0);
        cpuReg.status.C <= #DELAY (cpuReg.A > subValue);
    endtask : sub

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task incriment(input [7:0] code, input [7:0] data);
        case (code)
            INX : begin
                cpuReg.X        <= #DELAY cpuReg.X + 1'b1;
                cpuReg.status.N <= #DELAY ((cpuReg.X + 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((cpuReg.X + 1'b1) == 8'h00);
            end
            INY : begin
                cpuReg.Y        <= #DELAY cpuReg.Y + 1'b1;
                cpuReg.status.N <= #DELAY ((cpuReg.Y + 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((cpuReg.Y + 1'b1) == 8'h00);
            end
            INC_ZERO, INC_ZEROX, INC_ABS, INC_ABSX : begin
                writeData       <= #DELAY data + 1'b1;
                cpuReg.status.N <= #DELAY ((data + 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((data + 1'b1) == 8'h00);
            end
        endcase
    endtask : incriment

    /*********************************************************************//**
    * @brief
    * @param[in]
    * 　　　　　　　
    * @return       None
    **********************************************************************/
    task decriment(input [7:0] code, input [7:0] data);
        case (code)
            DEX : begin
                cpuReg.X        <= #DELAY cpuReg.X - 1'b1;
                cpuReg.status.N <= #DELAY ((cpuReg.X - 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((cpuReg.X - 1'b1) == 8'h00);
            end
            DEY : begin
                cpuReg.Y        <= #DELAY cpuReg.Y - 1'b1;
                cpuReg.status.N <= #DELAY ((cpuReg.Y - 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((cpuReg.Y - 1'b1) == 8'h00);
            end
            DEC_ZERO, DEC_ZEROX, DEC_ABS, DEC_ABSX : begin
                writeData       <= #DELAY data - 1'b1;
                cpuReg.status.N <= #DELAY ((data - 1'b1) & 8'h80) ? TRUE : FALSE;
                cpuReg.status.Z <= #DELAY ((data - 1'b1) == 8'h00);
            end
        endcase
    endtask : decriment
endmodule