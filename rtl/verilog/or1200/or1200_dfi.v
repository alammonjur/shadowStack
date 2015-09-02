`include "timescale.v"
`include "or1200_defines.v"

module or1200_dfi(
    clk, rst,
    ex_insn, ex_lsu_op, dcpu_adr_o,
    ex_addrbase, ex_addrofs, ex_pc
);


// Inputs
input   clk;    // clock
input   rst;    // reset signal

input[31:0]     ex_insn;    // instruction from execute stage
input[`OR1200_LSUOP_WIDTH-1:0]  ex_lsu_op;  // load/store opcode from execute stage
input[31:0]     dcpu_adr_o; // memory address calculated from adding offset to register value

// For debugging purposes
input[31:0]     ex_addrbase;    // register value from execute stage for base memory address
input[31:0]     ex_addrofs;     // offset value from execute stage
input[31:0]     ex_pc;          // program counter for instruction in execute stage


// Internal regs and wires
reg     modified;   // Indicates whether return address is modified

reg[(1<<24)-1:0]    tags;   // table of 1-bit tags, each associated with a stack location. Assuming that
                            // the stack has 32-bit address space, the table should require 2^32 slots. 
                            // However, using 32 causes (1<<32)-1 result to overflow into the negatives, 
                            // probably because the address space for iSim's development environment is 
                            // actually 32 bits, so we will use 24 bits for now. 


// Check execution opcode at every cycle
always @(posedge clk or `OR1200_RST_EVENT rst) begin
    if (rst == `OR1200_RST_VALUE) begin
        // reset
    end
    else begin
        case (ex_lsu_op)
            // store word
            `OR1200_LSUOP_SW: begin
                // Encountering store instructions using link register means that the return address will be
                // pushed into the stack. For these instructions, clear the tag bit of the stack location of
                // where the return address would be stored. The attacker cannot modify the link register
                // directly, so the return address in the link register is correct at the time of a new function
                // call.
                // All other stores set the tag bits of the stack location of where the value in the source
                // register of the instruction would be stored
                
                tags[dcpu_adr_o+:4] <= (ex_insn[15:11] == 5'd9) ? 4'b0000 : 4'b1111;
                // 5'd9 is data submission reg r9
                
                // debugging
                if (ex_insn[15:11] == 5'd9) begin
                    $display("SW for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);;
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("ex_addrbase: %h", ex_addrbase);
                    $display("ex_addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end
            
            // store half-word
            `OR1200_LSUOP_SH: begin
                // Similar logic for other store instructions
                tags[dcpu_adr_o+:2] <= (ex_insn[15:11] == 5'd9) ? 2'b00 : 2'b11;

                // debugging
                if (ex_insn[15:11] == 5'd9) begin
                    $display("SH for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);;
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("ex_addrbase: %h", ex_addrbase);
                    $display("ex_addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end
            
            // store byte
            `OR1200_LSUOP_SB: begin
                tags[dcpu_adr_o] <= (ex_insn[15:11] == 5'd9) ? 1'b0 : 1'b1;
                
                // debugging
                if (ex_insn[15:11] == 5'd9) begin
                    $display("SB for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);;
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("ex_addrbase: %h", ex_addrbase);
                    $display("ex_addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end

            // load word
            `OR1200_LSUOP_LWZ, `OR1200_LSUOP_LWS: begin
                // Only check the corresponding tags for instructions that load return address from memory to
                // link register. Link register would be the destination register in this case.
                // If any of those tag bits is 1, that means the return address has been modified since the
                // link register store instruction.
                modified <= ex_insn[25:21] == 5'd9 && tags[dcpu_adr_o+:4] != 4'b0000;

                // debugging
                if (ex_insn[25:21] == 5'd9) begin
                    $display("LWZ or LWS for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("ex_addrbase: %h", ex_addrbase);
                    $display("ex_addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end

            // load half-word
            `OR1200_LSUOP_LHZ, `OR1200_LSUOP_LHS: begin
                // Similar logic for other load instructions
                modified <= ex_insn[25:21] == 5'd9 && tags[dcpu_adr_o+:2] != 2'b00;

                // debugging
                if (ex_insn[25:21] == 5'd9) begin
                    $display("LHZ or LHS for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("ex_addrbase: %h", ex_addrbase);
                    $display("ex_addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end

            // load byte
            `OR1200_LSUOP_LBZ, `OR1200_LSUOP_LBS: begin
                modified <= ex_insn[25:21] == 5'd9 && tags[dcpu_adr_o] != 1'b0;

                // debugging
                if (ex_insn[25:21] == 5'd9) begin
                    $display("LBZ or LBS for r9");
                    $display("ex_lsu_op: %h", ex_lsu_op);
                    $display("ex_rf_addrw: %d", ex_insn[25:21]);
                    $display("ex_rf_addra: %d", ex_insn[20:16]);
                    $display("ex_rf_addrb: %d", ex_insn[15:11]);
                    $display("addrbase: %h", ex_addrbase);
                    $display("addrofs: %h", ex_addrofs);
                    $display("dcpu_adr_o: %h", dcpu_adr_o);
                    $display("ex_pc: %h", ex_pc);
                end
            end

            // Not a load or store instruction
            default: begin
                modified <= 1'b0;
            end
        endcase
    end
end

// Exception handler when detecting return address modification
always @(modified) begin
    if (modified == 1'b1) begin
        $display("***********************Return address has been modified before PC=%h", ex_pc);
    end
end

endmodule

