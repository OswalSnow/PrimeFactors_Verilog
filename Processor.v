//Diseño procesador von neumann
module VonNeumannProcessor(
    input wire clk,
    input wire reset,
    input wire wr,
    input wire [5:0] address,
    input wire [9:0] data_in,
    output wire [9:0] data_out
);

// Definición de parámetros
parameter ADDR_WIDTH = 6; // Dirección de memoria de 64 direcciones (2^6 = 64)
parameter DATA_WIDTH = 10; // Ancho de palabra de 10 bits
parameter OPCODE_WIDTH = 4; // Ancho de código de operación

// Definición de códigos de operación
localparam OP_MOV = 4'b0000;
localparam OP_STORE = 4'b0001;
localparam OP_LOAD = 4'b0010;
localparam OP_PUSH = 4'b0011;
localparam OP_POP = 4'b0100;
localparam OP_ADD = 4'b0101;
localparam OP_SUB = 4'b0110;
localparam OP_MUL = 4'b0111;
localparam OP_DIV = 4'b1000;
localparam OP_AND = 4'b1001;
localparam OP_OR = 4'b1010;
localparam OP_XOR = 4'b1011;
localparam OP_NOT = 4'b1100;
localparam OP_JUMP = 4'b1101;
localparam OP_JUMPC = 4'b1110;

// Definición de registros
reg [DATA_WIDTH-1:0] accumulator;
reg [ADDR_WIDTH-1:0] program_counter;
reg [OPCODE_WIDTH-1:0] instruction_register;
reg [ADDR_WIDTH-1:0] stack_pointer;
reg [DATA_WIDTH-1:0] memory [0:63];
reg [DATA_WIDTH-1:0] rx;

// Asignación de pines de salida
assign data_out = accumulator;

// Comportamiento del procesador
always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
        program_counter <= 0;
        instruction_register <= 0;
        stack_pointer <= 0;
    end else begin
        if (wr) begin
            memory[address] <= data_in;
        end else begin
            // Selecciona la instrucción de la memoria según el contador de programa
            instruction_register <= memory[program_counter][DATA_WIDTH-1:DATA_WIDTH-OPCODE_WIDTH];
            
            // Extraer el dato de la instrucción
            rx <= memory[program_counter][DATA_WIDTH-OPCODE_WIDTH-1:0];
            
            // Decodifica la instrucción
            case(instruction_register)
                OP_MOV: accumulator <= data_in;
                OP_STORE: memory[rx] <= accumulator;
                OP_LOAD: accumulator <= memory[rx];
                OP_PUSH: begin
                            stack_pointer <= stack_pointer + 1;
                            memory[stack_pointer] <= accumulator;
                         end
                OP_POP: begin
                           accumulator <= memory[stack_pointer];
                           stack_pointer <= stack_pointer - 1;
                       end
                OP_ADD: accumulator <= accumulator + memory[rx];
                OP_SUB: accumulator <= accumulator - memory[rx];
                OP_MUL: accumulator <= accumulator * memory[rx];
                OP_DIV: accumulator <= accumulator / memory[rx];
                OP_AND: accumulator <= accumulator & memory[rx];
                OP_OR: accumulator <= accumulator | memory[rx];
                OP_XOR: accumulator <= accumulator ^ memory[rx];
                OP_NOT: accumulator <= ~accumulator;
                OP_JUMP: program_counter <= rx;
                OP_JUMPC: if (accumulator == 0) program_counter <= rx;
            endcase
            
            // Incrementa el contador de programa
            program_counter <= program_counter + 1;
        end
    end
end

endmodule

