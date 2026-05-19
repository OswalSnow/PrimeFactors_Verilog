//Testbench
module VonNeumannProcessor_Testbench();

    // Parámetros de prueba
    localparam ADDR_WIDTH = 6;
    localparam DATA_WIDTH = 10;
	localparam periodo=2;
    // Señales del testbench
    reg clk, wr;
    reg reset;
    reg [9:0] data_in;
    reg [5:0] address;
    wire [9:0] data_out;
	integer i;
    // Instancia del procesador
    VonNeumannProcessor dut (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .address(address),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Generación de señales de clock
    always #(periodo/2) clk = ~clk;

    // Inicialización de señales
    initial begin
        clk = 0;
        reset = 1;
        data_in = 0;
        wr = 1; //escribir instrucciones en memoria

        // Esperar un poco para asegurarnos de que el reset sea efectivo
        #(periodo*4);
        reset = 0;
	    
        //inicializa memoria con 0
		for (i=0; i< 64; i=i+1) begin
			address=i; data_in=0;#(periodo*3); end
		// Cargar programa en memoria 
        // Instrucción 1: LOAD 34
        // Instrucción 2: ADD 35
        // Instrucción 3: STORE 36
        address = 34; data_in = 5; #(periodo*3); // Cargar el primer número (5) en la dirección 34
        address = 35; data_in = 7; #(periodo*3); // Cargar el segundo número (7) en la dirección 35
        address = 33; data_in = 6; #(periodo*3);
		address = 0; data_in = {4'b0010, 6'b100010}; #(periodo*3); // LOAD 34
        address = 1; data_in = {4'b0101, 6'b100011}; #(periodo*3); // ADD 35
        address = 2; data_in = {4'b0001, 6'b100100}; #(periodo*3); // STORE 36
		address = 3; data_in = {4'b0110, 6'b100010}; #(periodo*3); // sub 34
        address = 4; data_in = {4'b0001, 6'b100101}; #(periodo*3); // STORE 37
		reset = 0;wr=0; #(periodo*3);
        // Asegurar que el procesador complete la ejecución
        #(periodo*100);

        // Detener simulación
        $stop;
    end

    // Monitorear el registro de acumulador
    always @(posedge clk) begin
        $display("Acumulador: %d", data_out);
    end

endmodule

