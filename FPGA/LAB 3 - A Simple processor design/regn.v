module regn(R, Rin, Clock, Q);

parameter n = 9;
input wire [n-1:0] R;
input wire Rin, Clock;
output reg [n-1:0] Q;

always @(posedge Clock)
	if (Rin)
		Q <= R;
endmodule
