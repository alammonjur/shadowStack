`include "timescale.v"
`include "or1200_defines.v"

module or1200_shadowstk(
    clk, rst,
    id_insn, id_pc, ex_freeze, operand_b
);

// I/O
input			    clk;
input			    rst;
input   [31:0]	    id_insn;    // Instruction from instruction decode stage
input	[31:0]		id_pc;      // Program counter from instruction decode stage
input			    ex_freeze;  
input	[31:0]		operand_b;  // Value in source register

// Internal regs and wires
reg	[32*256-1:0]	stack;  // Shadow stack storage
reg	[31:0]		    ssp;	// Shadow stack pointer
reg	[31:0]		    ra;     // Return address popped from shadow stack

// Always trigger at each rising edge or reset
always @(posedge clk or `OR1200_RST_EVENT rst) begin
    if (rst == `OR1200_RST_VALUE) begin
        ssp <=	32'd0;
        $display("Reset has occurred!");
    end
    else if (!ex_freeze) begin
        case (id_insn[31:26])

            `OR1200_OR32_JAL, `OR1200_OR32_JALR: begin
                // Push return address to shadow stack
                stack[ssp+31-:32] <= id_pc;
                ssp <=	ssp + 32;
                $display("Pushed %h into ShadowStack[%d:%d]", id_pc, ssp+31, ssp);
            end

            `OR1200_OR32_JR: begin
                // JR is also used when returning from function call, but R9
                // (link register) is used as source register in this case 
                if (id_insn[15:11] == 5'd9) begin
                    // Pop return address from shadow stack
                    ra  <=	stack[ssp-1-:32];
                    ssp <=	ssp - 32;
                    $display("Popped %h from ShadowStack[%d:%d]", stack[ssp-1-:32], ssp-1, ssp-32);
                end
            end
        endcase
    end
end

// Trigger whenever the popped return address value changes
always @(ra) begin
    // In nested subroutine calls, when returning from one subroutine to
    // another, link register restores its previous value from the real stack.
    if (operand_b != ra) begin
        $display("%h in stack does not match with %h in shadow", operand_b, ra);
    end		
    else begin
        $display("%h in stack matches %h in shadow", operand_b, ra);	
    end
end

endmodule
