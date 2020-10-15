module proc (DIN, Resetn, Clock, Run, Done, BusWires,IR,
			IR_en_regn,R0,R1,R2,R3,R4,R5,R6,R7 ,Tstep_Q,Tstep_D,
			Gin,AddSub,Ain,A_out,AddSub_out,Gout_from_reg); 
			
input wire [8:0] DIN;
input wire Resetn, Clock, Run;
output reg Done;
output wire [8:0] BusWires; // mux output
output reg [1:0]Tstep_Q; //current state
output reg [1:0]Tstep_D; //ns state
parameter T0 = 2'b00, T1 = 2'b01, T2 = 2'b10, T3 = 2'b11;
parameter mv = 3'b000, mvi = 3'b001, add = 3'b010, sub=3'b011, addi=3'b100 , subi = 3'b101;//....
parameter Alu_add = 1'b0, Alu_sub = 1'b0; 
reg [7:0] Rin_to_regn; //enable - bus of wires to reg
output reg Gin,AddSub,Ain; 
reg [7:0] Rout_control_to_mux; //bus to mux
reg Gout,DINout;
output reg IR_en_regn;

//instruction wires
output wire [8:0] IR;

// instruction code: IIIXXXYYY
wire [2:0] I; //III
wire [7:0] Xreg; //XXX
wire [7:0] Yreg;  //YYY

//... declare variables
assign I = IR[8:6];
dec3to8 decX (IR[5:3], 1'b1, Xreg); //Xreg ready to choose the specific regn.
dec3to8 decY (IR[2:0], 1'b1, Yreg);

//output from reg 
output wire [8:0] R0,R1,R2,R3,R4,R5,R6,R7; //the value in reg or we can call it the output of reg num i.
output wire [8:0] A_out,AddSub_out,Gout_from_reg;

// define the bus (the output from the mux): get the specific Rout and update the value to Bus wires.


// Control FSM state table always @(Tstep_Q, Run, Done) begin
	always @(Tstep_Q, Run, Done)
	begin
		case (Tstep_Q)
		T0: Tstep_D = (~Run)?T0:T1;
		T1: Tstep_D = (Done)?T0:T2;
		T2: Tstep_D = T3;
		T3: Tstep_D = T0;
		endcase
	end


// Control FSM outputs always @(Tstep_Q or I or Xreg or Yreg) begin
		always @(Tstep_Q or I or Xreg or Yreg) 
		begin
			Rin_to_regn = 8'b0;
			Rout_control_to_mux = 8'b0;
			DINout = 1'b0;
			Gin = 1'b0;
			Gout = 1'b0;
			AddSub = 1'b0;
			Ain = 1'b0;
			IR_en_regn = 1'b0;
			Done = 1'b0;
		//... specify initial values case (Tstep_Q) 
			case(Tstep_Q)
			T0: begin  // store DIN in IR in time step 0 begin
					IR_en_regn <= 1'b1;
				end
			T1: begin//define signals in time step 1 case (I) ... endcase
					case (I)
						mv: 
							 begin
								Rin_to_regn <= Xreg;
								Rout_control_to_mux <= Yreg;
								Done <= 1'b1;
							 end
						mvi:
							 begin
								Rin_to_regn <= Xreg;
								DINout =1'b1;
								Done <= 1'b1;
							 end
						add:
						 begin
							Rout_control_to_mux <= Xreg;
							Ain =1'b1;	
						 end
						 sub:
						 begin
							Rout_control_to_mux <= Xreg;
							Ain =1'b1;	
						 end
						 addi :
							begin
							Rout_control_to_mux <= Xreg;
							Ain =1'b1;	
							end
						subi:
							begin
							Rout_control_to_mux <= Xreg;
							Ain =1'b1;	
							end
							
					endcase
				end
				
			T2: begin//define signals in time step 2 case (I) ... endcase
					case(I)
						add:
							begin
								AddSub = 1'b1; //Addsub =1;
								Rout_control_to_mux <= Yreg;
								Gin = 1'b1;
							end
						sub:
							begin
								AddSub = 1'b0; //Addsub =1;
								Rout_control_to_mux <= Yreg;
								Gin = 1'b1;
							end
						addi:
							begin
							AddSub = 1'b1;
							DINout =1'b1;
							Gin = 1'b1;
							end
						subi:
							begin
							AddSub = 1'b0;
							DINout =1'b1;
							Gin = 1'b1;
							end	
					endcase
				end
			T3:
				begin //define signals in time step 3
				Rin_to_regn <= Xreg;
				Gout = 1'b1;
				Done = 1'b1;	
				end			
			endcase
		end
//Output and install the values into bus.	
	assign BusWires =   (DINout)?DIN:
					(Rout_control_to_mux[0])?R0:  //choose R0
					(Rout_control_to_mux[1])?R1:
					(Rout_control_to_mux[2])?R2:
					(Rout_control_to_mux[3])?R3:
					(Rout_control_to_mux[4])?R4:
					(Rout_control_to_mux[5])?R5:
					(Rout_control_to_mux[6])?R6:
					(Rout_control_to_mux[7])?R7:
					(Gout)?Gout_from_reg:          //Choose G
					DIN; 

//ALU
	assign AddSub_out = (AddSub)?(A_out + BusWires):(A_out - BusWires);

// Update registers
regn reg_0 (.R(BusWires),.Rin(Rin_to_regn[0]), .Clock(Clock), .Q(R0)); // if enable than Buswires(info) -> R0(Update the data from regn num 0) 
regn reg_1 (.R(BusWires),.Rin(Rin_to_regn[1]), .Clock(Clock), .Q(R1));
regn reg_2 (.R(BusWires),.Rin(Rin_to_regn[2]), .Clock(Clock), .Q(R2));
regn reg_3 (.R(BusWires),.Rin(Rin_to_regn[3]), .Clock(Clock), .Q(R3));
regn reg_4 (.R(BusWires),.Rin(Rin_to_regn[4]), .Clock(Clock), .Q(R4));
regn reg_5 (.R(BusWires),.Rin(Rin_to_regn[5]), .Clock(Clock), .Q(R5));
regn reg_6 (.R(BusWires),.Rin(Rin_to_regn[6]), .Clock(Clock), .Q(R6));
regn reg_7 (.R(BusWires),.Rin(Rin_to_regn[7]), .Clock(Clock), .Q(R7));
regn reg_IR(.R(DIN),.Rin(IR_en_regn),.Clock(Clock),.Q(IR));

//add
regn reg_A (.R(BusWires),.Rin(Ain), .Clock(Clock), .Q(A_out));
regn reg_G (.R(AddSub_out),.Rin(Gin), .Clock(Clock), .Q(Gout_from_reg));


// Control FSM flip-flops 
always @(posedge Clock, negedge Resetn) 
	begin
	if (!Resetn)
		Tstep_Q <= T0;
	else
		Tstep_Q <= Tstep_D;
	end

endmodule
