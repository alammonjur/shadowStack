`include "timescale.v"
`include "or1200_defines.v"

module or1200_shadowstk(
	clk, rst,
	id_insn, ex_pc, ex_freeze, operand_b
);

input			clk;
input			rst;
input	[31:0]		id_insn;
input	[31:0]		ex_pc;
input			ex_freeze;
input	[31:0]		operand_b;


reg	[32*256-1:0]	stack;
reg	[31:0]		ssp;	// Shadow stack pointer
reg	[31:0]		ra;

always @(posedge clk or `OR1200_RST_EVENT rst) begin
	if (rst == `OR1200_RST_VALUE) begin
		ssp <=	32'd0;
		$display("Reset has occurred!");
	end
	else if (!ex_freeze) begin
		case (id_insn[31:26])
			
			`OR1200_OR32_JAL, `OR1200_OR32_JALR: begin
				stack[ssp+31-:32] <= ex_pc;
				ssp <=	ssp + 32;
				$display("Pushed %h into ShadowStack[%d:%d]", ex_pc, ssp+31, ssp);
			end
			
			`OR1200_OR32_JR: begin
				if (id_insn[15:11] == 5'd9) begin
					ra  <=	stack[ssp-1-:32];
					ssp <=	ssp - 32;
					$display("Popped %h from ShadowStack[%d:%d]", stack[ssp-1-:32], ssp-1, ssp-32);
				end
			end
		endcase
	end
end

always @(ra) begin
	if (operand_b != ra) begin
		$display("%h in stack does not match with %h in shadow", operand_b, ra);
	end		
	else begin
		$display("%h in stack matches %h in shadow", operand_b, ra);	
	end
end

endmodule
