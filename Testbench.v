module VonNeumannProcessor_Testbench();
	localparam DATA_WIDTH = 10;
	localparam periodo = 2;
	// Opcodes
	localparam OP_MOV  = 5'b00000;
	localparam OP_SUB  = 5'b00010;
	localparam OP_MUL  = 5'b00011;
	localparam OP_DIV  = 5'b00100;
	localparam OP_ADDI = 5'b00101;
	localparam OP_BGE  = 5'b10111;
	localparam OP_BLT  = 5'b10110;
	localparam OP_J    = 5'b11000;
	localparam OP_LW   = 5'b11100;
	localparam OP_SW   = 5'b11101;

	// Señales
	reg clk, wr, reset;
	reg [9:0] data_in;
	reg [5:0] address;
	wire [9:0] data_out;
	integer i;

	// Instancia
	VonNeumannProcessor dut (
		.clk(clk), .reset(reset), .wr(wr),
		.address(address), .data_in(data_in), .data_out(data_out)
	);

	always #(periodo/2) clk = ~clk;

	// Mostrar únicamente factores primos encontrados
	always @(posedge clk) begin
		if (
			dut.program_counter == 6'd21 &&
			dut.instruction_register == OP_LW &&
			dut.operand == 5'd29
		) begin
			$display(
				"Factorizando %d -> Factor primo encontrado: %d",
				dut.memory[28],
				dut.memory[29]
			);
		end
	end

	initial begin
		clk = 0;
		reset = 1;
		wr = 1;
		data_in = 0;

		#(periodo*4);

		reset = 0;

		// Limpiar memoria
		for (i = 0; i < 64; i = i + 1) begin
			address = i;
			data_in = 0;
			#(periodo*3);
		end

		// --- Mapa de datos (addr 28-31) ---
		// addr 28: N (número a factorizar)
		// addr 29: divisor
		// addr 30: cociente temporal
		// addr 31: producto/scratch

		address = 28;
		data_in = 10'd12;
		#(periodo*3); // N = 12

		// --- Programa (addr 0-27) ---

		// INIT: divisor = 2
		address = 0;
		data_in = {OP_MOV, 5'd2};
		#(periodo*3); // MOV 2

		address = 1;
		data_in = {OP_SW, 5'd29};
		#(periodo*3); // SW 29

		// MAIN_LOOP (addr 2): calcula residuo = N mod divisor

		address = 2;
		data_in = {OP_LW, 5'd28};
		#(periodo*3); // LW 28

		address = 3;
		data_in = {OP_DIV, 5'd29};
		#(periodo*3); // DIV 29

		address = 4;
		data_in = {OP_SW, 5'd30};
		#(periodo*3); // SW 30

		address = 5;
		data_in = {OP_LW, 5'd30};
		#(periodo*3); // LW 30

		address = 6;
		data_in = {OP_MUL, 5'd29};
		#(periodo*3); // MUL 29

		address = 7;
		data_in = {OP_SW, 5'd31};
		#(periodo*3); // SW 31

		address = 8;
		data_in = {OP_LW, 5'd28};
		#(periodo*3); // LW 28

		address = 9;
		data_in = {OP_SUB, 5'd31};
		#(periodo*3); // SUB 31

		address = 10;
		data_in = {OP_ADDI, 5'd1};
		#(periodo*3); // ADDI 1

		// FACTOR CHECK (addr 11)
		// si residuo >= 1 -> NO es factor -> INCREMENT

		address = 11;
		data_in = {OP_BGE, 5'd2};
		#(periodo*3); // BGE 2

		// Delay slot inocuo
		address = 12;
		data_in = {OP_MOV, 5'd0};
		#(periodo*3);

		// SI es factor -> FACTOR_FOUND
		address = 13;
		data_in = {OP_J, 5'd20};
		#(periodo*3); // J 20

		// Delay slot inocuo
		address = 14;
		data_in = {OP_MOV, 5'd0};
		#(periodo*3);

		// INCREMENT

		address = 15;
		data_in = {OP_LW, 5'd29};
		#(periodo*3); // LW 29

		address = 16;
		data_in = {OP_ADDI, 5'd1};
		#(periodo*3); // ADDI 1

		address = 17;
		data_in = {OP_SW, 5'd29};
		#(periodo*3); // SW 29

		address = 18;
		data_in = {OP_J, 5'd2};
		#(periodo*3); // J 2

		// Delay slot inocuo
		address = 19;
		data_in = {OP_MOV, 5'd0};
		#(periodo*3);

		// FACTOR_FOUND

		address = 20;
		data_in = {OP_LW, 5'd29};
		#(periodo*3); // FACTOR PRIMO

		address = 21;
		data_in = {OP_LW, 5'd30};
		#(periodo*3); // nuevo N

		address = 22;
		data_in = {OP_SW, 5'd28};
		#(periodo*3); // N = cociente

		// Verificar N < 2 para HALT

		address = 23;
		data_in = {OP_BLT, 5'd2};
		#(periodo*3); // BLT 2

		// Delay slot inocuo
		address = 24;
		data_in = {OP_MOV, 5'd0};
		#(periodo*3);

		// mismo divisor -> MAIN_LOOP
		address = 25;
		data_in = {OP_J, 5'd2};
		#(periodo*3); // J 2

		// Delay slot inocuo
		address = 26;
		data_in = {OP_MOV, 5'd0};
		#(periodo*3);

		// HALT infinito
		address = 27;
		data_in = {OP_J, 5'd27};
		#(periodo*3);

		// Iniciar ejecución desde addr 0
		reset = 1;
		#(periodo*2);

		reset = 0;
		wr = 0;

		// Ciclos suficientes para factorizar 12 = 2 × 2 × 3
		#(periodo*600);

		$stop;
	end
endmodule