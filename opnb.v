
module opnb(CLK, BPhiM, BA, BnRD, BnWR, BnCS, BnIC, BRA23, BRA22, BRA21, BRA20, BRAD, BRA9, BRA8, BRMPX, BnROE, BPAD, BPA11, BPA10, BPA9, BPA8, BPMPX, BnPOE, MDQ, MnWE, MnCAS, MnRAS, MnCS, MBA, MA, MCKE, MDQM, VnCS, VSCLK, VSDI, A, nRD, nWR, nCS, D, nIC, nDSW, JTAG);
   input            CLK;
   output           BPhiM;
   output [1:0]     BA;
   output           BnRD;
   output           BnWR;
   output           BnCS;
   output           BnIC;
   input            BRA23;
   input            BRA22;
   input            BRA21;
   input            BRA20;
   inout [7:0]      BRAD;
   input            BRA9;
   input            BRA8;
   input            BRMPX;
   input            BnROE;
   inout [7:0]      BPAD;
   input            BPA11;
   input            BPA10;
   input            BPA9;
   input            BPA8;
   input            BPMPX;
   input            BnPOE;
   inout [7:0]      MDQ;
   output           MnWE;
   output           MnCAS;
   output           MnRAS;
   output           MnCS;
   output [1:0]     MBA;
   output [12:0]    MA;
   output           MCKE;
   output           MDQM;
   output           VnCS;
   reg              VnCS;
   output           VSCLK;
   reg              VSCLK;
   output           VSDI;
   reg              VSDI;
   input [2:0]      A;
   input            nRD;
   input            nWR;
   input [3:0]      nCS;
   inout [7:0]      D;
   input            nIC;
   input [3:0]      nDSW;
   input [3:0]      JTAG;
   
   reg [1:0]        clk32div4;
   reg [1:0]        srrmpx;
   reg [23:0]       ra;
   reg              rreq;
   reg [1:0]        srpmpx;
   reg [23:0]       pa;
   reg              preq;
   parameter        tRFCmin = 3;
   parameter        tRFC = 250;
   reg [7:0]        refcnt;
   reg              refreq;
   parameter [4:0]  mem_state_MS_INIT_0 = 0,
                    mem_state_MS_INIT_1 = 1,
                    mem_state_MS_INIT_2 = 2,
                    mem_state_MS_INIT_REFRESH_0 = 3,
                    mem_state_MS_INIT_REFRESH_1 = 4,
                    mem_state_MS_INIT_MODE_0 = 5,
                    mem_state_MS_INIT_MODE_1 = 6,
                    mem_state_MS_INIT_MODE_2 = 7,
                    mem_state_MS_IDLE = 8,
                    mem_state_MS_REFRESH_0 = 9,
                    mem_state_MS_REFRESH_1 = 10,
                    mem_state_MS_READ_0 = 11,
                    mem_state_MS_READ_1 = 12,
                    mem_state_MS_READ_2 = 13,
                    mem_state_MS_READ_3 = 14,
                    mem_state_MS_READ_4 = 15,
                    mem_state_MS_WRITE_0 = 16,
                    mem_state_MS_WRITE_1 = 17,
                    mem_state_MS_WRITE_2 = 18,
                    mem_state_MS_PRECHARGE = 19;
   reg [4:0]        mstate;
   reg [2:0]        rfccnt;
   reg [1:0]        rfcwcnt;
   reg [7:0]        mmdq;
   reg [3:0]        mmcmd;
   reg [1:0]        mmba;
   reg [12:0]       mma;
   reg              mmcke;
   reg              mmdqm;
   reg              moe;
   reg [24:0]       madr;
   reg [7:0]        rad;
   reg              rack;
   reg [7:0]        pad;
   reg              pack;
   reg              refack;
   reg              wack;
   parameter [3:0]  CMD_NOP = 4'b0111;
   parameter [3:0]  CMD_ACTIVE = 4'b0011;
   parameter [3:0]  CMD_READ = 4'b0101;
   parameter [3:0]  CMD_WRITE = 4'b0100;
   parameter [3:0]  CMD_PRECHARGE = 4'b0010;
   parameter [3:0]  CMD_REFRESH = 4'b0001;
   parameter [3:0]  CMD_MODE = 4'b0000;
   parameter [1:0]  vol_state_VS_WAIT = 0,
                    vol_state_VS_IDLE = 1,
                    vol_state_VS_WRITE_0 = 2,
                    vol_state_VS_WRITE_1 = 3;
   reg [1:0]        vstate;
   reg [4:0]        vcnt;
   reg              vack;
   reg [1:0]        sric;
   reg [1:0]        srwrcs;
   reg [1:0]        srrdcs;
   reg [3:0]        regnum;
   reg [24:0]       wadr;
   reg [7:0]        wa;
   reg [7:0]        wdat;
   reg              wreq;
   reg [7:0]        vdat;
   reg              vreq;
   reg [7:0]        rdat;
   reg              selncs;
   
   
   always @(posedge CLK)
      
         clk32div4 <= {clk32div4[0], ((~clk32div4[1]))};
   
   assign BPhiM = clk32div4[1];
   assign BA = A[1:0];
   assign BnRD = nRD;
   assign BnWR = nWR;
   assign BnCS = ((A[2] == 1'b0 & selncs == 1'b0)) ? 1'b0 : 
                 1'b1;
   assign BnIC = ((sric[0] == 1'b0)) ? 1'b0 : 
                 ((sric[1] == 1'b0)) ? 1'b1 : 
                 1'bZ;
   
   assign BRAD = ((BnROE == 1'b0)) ? rad : 
                 8'bZZZZZZZZ;
   
   always @(negedge nIC or posedge CLK)
      if (nIC == 1'b0)
      begin
         srrmpx <= {2{1'b0}};
         ra <= {24{1'b0}};
         rreq <= 1'b0;
      end
      else 
      begin
         srrmpx <= {srrmpx[0], BRMPX};
         case (srrmpx)
            2'b01 :
               ra[9:0] <= {BRA9, BRA8, BRAD};
            2'b10 :
               begin
                  ra[23:20] <= {BRA23, BRA22, BRA21, BRA20};
                  ra[19:10] <= {BRA9, BRA8, BRAD};
                  rreq <= (~rreq);
               end
            default :
               ;
         endcase
      end
   
   assign BPAD = ((BnPOE == 1'b0)) ? pad : 
                 8'bZZZZZZZZ;
   
   always @(negedge nIC or posedge CLK)
      if (nIC == 1'b0)
      begin
         srpmpx <= {2{1'b0}};
         pa <= {24{1'b0}};
         preq <= 1'b0;
      end
      else 
      begin
         srpmpx <= {srpmpx[0], BPMPX};
         case (srpmpx)
            2'b01 :
               pa[11:0] <= {BPA11, BPA10, BPA9, BPA8, BPAD};
            2'b10 :
               begin
                  pa[23:12] <= {BPA11, BPA10, BPA9, BPA8, BPAD};
                  preq <= (~preq);
               end
            default :
               ;
         endcase
      end
   
   assign MDQ = ((moe == 1'b1)) ? mmdq : 
                8'bZZZZZZZZ;
   assign MnWE = mmcmd[0];
   assign MnCAS = mmcmd[1];
   assign MnRAS = mmcmd[2];
   assign MnCS = mmcmd[3];
   assign MBA = mmba;
   assign MA = mma;
   assign MCKE = mmcke;
   assign MDQM = mmdqm;
   
   always @(negedge nIC or posedge CLK)
      if (nIC == 1'b0)
      begin
         refcnt <= {8{1'b0}};
         refreq <= 1'b0;
         mstate <= mem_state_MS_INIT_0;
         rfccnt <= (8 - 1);
         rfcwcnt <= {2{1'b0}};
         mmdq <= {8{1'b0}};
         mmcmd <= CMD_NOP;
         mmba <= {2{1'b0}};
         mma <= {13{1'b0}};
         mmcke <= 1'b1;
         mmdqm <= 1'b1;
         moe <= 1'b0;
         madr <= {25{1'b0}};
         rad <= {8{1'b0}};
         rack <= 1'b0;
         pad <= {8{1'b0}};
         pack <= 1'b0;
         refack <= 1'b0;
         wack <= 1'b0;
      end
      else 
      begin
         
         if (refcnt == 0)
         begin
            refcnt <= (tRFC - 1);
            refreq <= (~refreq);
         end
         else
            refcnt <= refcnt - 1;
         
         case (mstate)
            mem_state_MS_INIT_0 :
               begin
                  mmcmd <= CMD_NOP;
                  mmcke <= 1'b1;
                  mstate <= mem_state_MS_INIT_1;
               end
            
            mem_state_MS_INIT_1 :
               begin
                  mmcmd <= CMD_NOP;
                  mstate <= mem_state_MS_INIT_2;
               end
            mem_state_MS_INIT_2 :
               begin
                  mmcmd <= CMD_PRECHARGE;
                  mma[10] <= 1'b1;
                  mstate <= mem_state_MS_INIT_REFRESH_0;
               end
            
            mem_state_MS_INIT_REFRESH_0 :
               begin
                  mmcmd <= CMD_REFRESH;
                  rfcwcnt <= (tRFCmin - 2);
                  mstate <= mem_state_MS_INIT_REFRESH_1;
               end
            mem_state_MS_INIT_REFRESH_1 :
               begin
                  mmcmd <= CMD_NOP;
                  if (rfcwcnt != 0)
                     rfcwcnt <= rfcwcnt - 1;
                  else if (rfccnt != 0)
                  begin
                     rfccnt <= rfccnt - 1;
                     mstate <= mem_state_MS_INIT_REFRESH_0;
                  end
                  else
                     mstate <= mem_state_MS_INIT_MODE_0;
               end
            
            mem_state_MS_INIT_MODE_0 :
               begin
                  mmcmd <= CMD_MODE;
                  mmba <= 2'b00;
                  mma[12:10] <= 3'b000;
                  mma[9] <= 1'b1;
                  mma[8:7] <= 2'b00;
                  mma[6:4] <= 3'b010;
                  mma[3] <= 1'b0;
                  mma[2:0] <= 3'b000;
                  mstate <= mem_state_MS_INIT_MODE_1;
               end
            mem_state_MS_INIT_MODE_1 :
               begin
                  mmcmd <= CMD_NOP;
                  mstate <= mem_state_MS_IDLE;
               end
            
            mem_state_MS_IDLE :
               begin
                  mmcmd <= CMD_NOP;
                  if (pack != preq)
                  begin
                     madr <= {1'b0, pa};
                     mstate <= mem_state_MS_READ_0;
                  end
                  else if (rack != rreq)
                  begin
                     madr <= {1'b1, ra};
                     mstate <= mem_state_MS_READ_0;
                  end
                  else if (refack != refreq)
                  begin
                     madr <= wadr;
                     mmdq <= wdat;
                     mstate <= mem_state_MS_REFRESH_0;
                  end
                  else if (wack != wreq)
                  begin
                     madr <= wadr;
                     mmdq <= wdat;
                     mstate <= mem_state_MS_WRITE_0;
                  end
               end
            
            mem_state_MS_REFRESH_0 :
               begin
                  mmcmd <= CMD_REFRESH;
                  rfcwcnt <= (tRFCmin - 2);
                  refack <= refreq;
                  mstate <= mem_state_MS_REFRESH_1;
               end
            mem_state_MS_REFRESH_1 :
               begin
                  mmcmd <= CMD_NOP;
                  if (rfcwcnt != 0)
                     rfcwcnt <= rfcwcnt - 1;
                  else
                     mstate <= mem_state_MS_IDLE;
               end
            
            mem_state_MS_READ_0 :
               begin
                  mmcmd <= CMD_ACTIVE;
                  mmba <= madr[24:23];
                  mma <= madr[22:10];
                  if (madr[24] == 1'b0)
                     pack <= preq;
                  else
                     rack <= rreq;
                  mstate <= mem_state_MS_READ_1;
               end
            mem_state_MS_READ_1 :
               begin
                  mmcmd <= CMD_READ;
                  mma[10] <= 1'b0;
                  mma[9:0] <= madr[9:0];
                  mmdqm <= 1'b0;
                  mstate <= mem_state_MS_READ_2;
               end
            mem_state_MS_READ_2 :
               begin
                  mmcmd <= CMD_NOP;
                  mmdqm <= 1'b1;
                  mstate <= mem_state_MS_READ_3;
               end
            mem_state_MS_READ_3 :
               begin
                  mmcmd <= CMD_NOP;
                  mstate <= mem_state_MS_READ_4;
               end
            mem_state_MS_READ_4 :
               begin
                  mmcmd <= CMD_NOP;
                  if (madr[24] == 1'b0)
                     pad <= MDQ;
                  else
                     rad <= MDQ;
                  mstate <= mem_state_MS_PRECHARGE;
               end
            
            mem_state_MS_WRITE_0 :
               begin
                  mmcmd <= CMD_ACTIVE;
                  mmba <= madr[24:23];
                  mma <= madr[22:10];
                  wack <= wreq;
                  mstate <= mem_state_MS_WRITE_1;
               end
            mem_state_MS_WRITE_1 :
               begin
                  mmcmd <= CMD_WRITE;
                  mma[10] <= 1'b0;
                  mma[9:0] <= madr[9:0];
                  mmdqm <= 1'b0;
                  moe <= 1'b1;
                  mstate <= mem_state_MS_WRITE_2;
               end
            mem_state_MS_WRITE_2 :
               begin
                  mmcmd <= CMD_NOP;
                  mmdqm <= 1'b1;
                  moe <= 1'b0;
                  mstate <= mem_state_MS_PRECHARGE;
               end
            
            mem_state_MS_PRECHARGE :
               begin
                  mmcmd <= CMD_PRECHARGE;
                  mma[10] <= 1'b1;
                  mstate <= mem_state_MS_IDLE;
               end
            
            default :
               mstate <= mem_state_MS_INIT_0;
         endcase
      end
   
   
   always @(negedge nIC or posedge CLK)
      if (nIC == 1'b0)
      begin
         vstate <= vol_state_VS_WAIT;
         vcnt <= {5{1'b1}};
         vack <= 1'b0;
         VnCS <= 1'b1;
         VSCLK <= 1'b0;
         VSDI <= 1'b0;
      end
      else 
      begin
         if (clk32div4 == 2'b00)
            case (vstate)
               vol_state_VS_WAIT :
                  begin
                     VnCS <= 1'b1;
                     VSCLK <= 1'b0;
                     VSDI <= 1'b0;
                     vstate <= vol_state_VS_IDLE;
                  end
               vol_state_VS_IDLE :
                  begin
                     VnCS <= 1'b1;
                     VSCLK <= 1'b0;
                     VSDI <= 1'b0;
                     vcnt <= {5{1'b1}};
                     if (vack != vreq)
                        vstate <= vol_state_VS_WRITE_0;
                  end
               vol_state_VS_WRITE_0 :
                  begin
                     VnCS <= 1'b0;
                     VSCLK <= (~vcnt[0]);
                     VSDI <= vdat[(vcnt[3:1])];
                     vcnt <= vcnt - 1;
                     if (vcnt == 5'b00000)
                        vstate <= vol_state_VS_WRITE_1;
                  end
               vol_state_VS_WRITE_1 :
                  begin
                     VnCS <= 1'b0;
                     VSCLK <= 1'b0;
                     VSDI <= 1'b0;
                     vack <= vreq;
                     vstate <= vol_state_VS_IDLE;
                  end
               default :
                  vstate <= vol_state_VS_IDLE;
            endcase
      end
   
   assign D = ((A[2] == 1'b1 & selncs == 1'b0 & nRD == 1'b0)) ? rdat : 
              8'bZZZZZZZZ;
   
   always @(negedge nIC or posedge CLK)
   begin: xhdl0
      reg              busy;
      if (nIC == 1'b0)
      begin
         sric <= {2{1'b0}};
         srwrcs <= {2{1'b0}};
         srrdcs <= {2{1'b0}};
         regnum <= {4{1'b0}};
         wadr <= {25{1'b0}};
         wa <= {8{1'b0}};
         wdat <= {8{1'b0}};
         wreq <= 1'b0;
         vdat <= {8{1'b0}};
         vreq <= 1'b0;
         rdat <= {8{1'b0}};
      end
      else 
      begin
         
         sric <= {sric[0], 1'b1};
         
         srwrcs <= {srwrcs[0], (A[2] & ((~selncs)) & ((~nWR)))};
         if (srwrcs == 2'b01)
            case (A[1:0])
               2'b00, 2'b10 :
                  regnum <= D[3:0];
               2'b01, 2'b11 :
                  case (regnum)
                     4'h1 :
                        wadr[24] <= D[0];
                     4'h2 :
                        begin
                           wadr[15:8] <= D;
                           wa <= {8{1'b0}};
                        end
                     4'h3 :
                        wadr[23:16] <= D;
                     4'h8 :
                        begin
                           wadr[7:0] <= wa;
                           wa <= wa + 1;
                           wdat <= D;
                           wreq <= (~wreq);
                        end
                     4'hb :
                        begin
                           vdat <= D;
                           vreq <= (~vreq);
                        end
                     default :
                        ;
                  endcase
               default :
                  ;
            endcase
         
         srrdcs <= {srrdcs[0], (A[2] & ((~selncs)) & ((~nRD)))};
         if (srrdcs == 2'b01)
         begin
            busy = (~((wreq ^ wack) | (vreq ^ vack)));
            case (A[1:0])
               2'b00, 2'b10 :
                  rdat <= {((~busy)), 3'b000, busy, busy, 2'b00};
               2'b01, 2'b11 :
                  rdat <= {((~busy)), 3'b000, busy, busy, 2'b00};
               default :
                  ;
            endcase
         end
      end
   end
   
   
   always @(nDSW or nCS)
   begin: xhdl1
      integer          n;
      n = (2'b11 ^ nDSW[1:0]);
      selncs <= nCS[n];
   end
   
endmodule



