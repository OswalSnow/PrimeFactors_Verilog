module VonNeumannProcessor(
    input wire clk,
    input wire reset,
    input wire wr,
    input wire [5:0] address,
    input wire [9:0] data_in,
    output wire [9:0] data_out
);

// Parámetros: 5 bits de opcode, 5 bits de operando
parameter ADDR_WIDTH = 6;
parameter DATA_WIDTH = 10;
parameter OPCODE_WIDTH = 5;  // 5 bits → 32 instrucciones máx.

// Definición de códigos de operación (32 instrucciones)
// Aritméticas
localparam OP_MOV  = 5'b00000;  // MOV  imm → acc (inmediato)
localparam OP_ADD  = 5'b00001;  // ADD  mem[addr] → acc = acc + mem
localparam OP_SUB  = 5'b00010;
localparam OP_MUL  = 5'b00011;
localparam OP_DIV  = 5'b00100;
localparam OP_ADDI = 5'b00101;  // ADDI imm → acc = acc + imm
localparam OP_SUBI = 5'b00110;
// Lógicas
localparam OP_AND  = 5'b00111;
localparam OP_OR   = 5'b01000;
localparam OP_XOR  = 5'b01001;
localparam OP_NOT  = 5'b01010;
localparam OP_ANDI = 5'b01011;
localparam OP_ORI  = 5'b01100;
localparam OP_XORI = 5'b01101;
// Desplazamientos
localparam OP_SLL  = 5'b01110;  // shift left logical  acc = acc << mem[addr]
localparam OP_SRL  = 5'b01111;  // shift right logical
localparam OP_SRA  = 5'b10000;  // shift right arithmetic
localparam OP_SLLI = 5'b10001;  // shift left logical inmediato
localparam OP_SRLI = 5'b10010;
localparam OP_SRAI = 5'b10011;
// Control de flujo
localparam OP_BEQ  = 5'b10100;  // branch if acc == imm
localparam OP_BNE  = 5'b10101;  // branch if acc != imm
localparam OP_BLT  = 5'b10110;  // branch if acc < imm (signed)
localparam OP_BGE  = 5'b10111;  // branch if acc >= imm (signed)
localparam OP_J    = 5'b11000;  // jump uncondicional a dirección imm
localparam OP_JAL  = 5'b11001;  // jump and link (guarda PC+1 en link_reg)
localparam OP_JALR = 5'b11010;  // jump and link registro (a partir de acc+imm)
localparam OP_LUI  = 5'b11011;  // load upper immediate (imm << 5)
// Memoria
localparam OP_LW   = 5'b11100;  // load word (igual al antiguo LOAD)
localparam OP_SW   = 5'b11101;  // store word (igual a STORE)
localparam OP_LB   = 5'b11110;  // load byte (con extensión de signo)
localparam OP_SB   = 5'b11111;  // store byte (bits bajos)
// Nota: PUSH/POP y JUMPC se pueden implementar con combinaciones,
// pero para no exceder 32 se han incluido como parte de otras.
// En este ejemplo se añade SLT y SLTI usando dos opcodes más,
// pero como ya usamos 32, se pueden reemplazar otros. 
// Para mantener 32 exactos se deja la lista anterior.

// Registros internos
reg [DATA_WIDTH-1:0] accumulator;
reg [ADDR_WIDTH-1:0] program_counter;
reg [OPCODE_WIDTH-1:0] instruction_register;
reg [ADDR_WIDTH-1:0] stack_pointer;
reg [DATA_WIDTH-1:0] memory [0:63];
reg [ADDR_WIDTH-1:0] link_reg;      // registro para JAL/JALR
reg [5:0] operand;                  // campo de 5 bits (inmediato o dirección)

assign data_out = accumulator;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
        program_counter <= 0;
        instruction_register <= 0;
        stack_pointer <= 0;
        link_reg <= 0;
    end else begin
        if (wr) begin
            memory[address] <= data_in;
        end else begin
            // Decodificación: opcode (bits 9:5), operando (bits 4:0)
            instruction_register <= memory[program_counter][DATA_WIDTH-1 : DATA_WIDTH-OPCODE_WIDTH];
            operand <= memory[program_counter][OPCODE_WIDTH-1 : 0];  // 5 bits
            // Incremento por defecto (se modifica en branches/jumps)
            program_counter <= program_counter + 1;
            
            case (instruction_register)
                // ---------- Movimiento e inmediatos ----------
                OP_MOV:  accumulator <= {5'b0, operand};      // extiende a 10 bits
                OP_ADDI: accumulator <= accumulator + {{5{operand[4]}}, operand}; // sign extend
                OP_SUBI: accumulator <= accumulator - {{5{operand[4]}}, operand};
                OP_ANDI: accumulator <= accumulator & {{5{operand[4]}}, operand};
                OP_ORI:  accumulator <= accumulator | {{5{operand[4]}}, operand};
                OP_XORI: accumulator <= accumulator ^ {{5{operand[4]}}, operand};
                OP_LUI:  accumulator <= {operand, 5'b0};     // desplaza 5 bits a la izquierda
                
                // ---------- Aritméticas y lógicas con memoria ----------
                OP_ADD: accumulator <= accumulator + memory[{1'b0, operand[4:0]}];
                OP_SUB: accumulator <= accumulator - memory[{1'b0, operand[4:0]}];
                OP_MUL: accumulator <= accumulator * memory[{1'b0, operand[4:0]}];
                OP_DIV: accumulator <= accumulator / memory[{1'b0, operand[4:0]}];
                OP_AND: accumulator <= accumulator & memory[{1'b0, operand[4:0]}];
                OP_OR:  accumulator <= accumulator | memory[{1'b0, operand[4:0]}];
                OP_XOR: accumulator <= accumulator ^ memory[{1'b0, operand[4:0]}];
                OP_NOT: accumulator <= ~accumulator;
                
                // ---------- Desplazamientos ----------
                OP_SLL:  accumulator <= accumulator << memory[{1'b0, operand[4:0]}];
                OP_SRL:  accumulator <= accumulator >> memory[{1'b0, operand[4:0]}];
                OP_SRA:  accumulator <= $signed(accumulator) >>> memory[{1'b0, operand[4:0]}];
                OP_SLLI: accumulator <= accumulator << operand;
                OP_SRLI: accumulator <= accumulator >> operand;
                OP_SRAI: accumulator <= $signed(accumulator) >>> operand;
                
                // ---------- Acceso a memoria (word y byte) ----------
                OP_LW: accumulator <= memory[{1'b0, operand[4:0]}];
                OP_SW: memory[{1'b0, operand[4:0]}] <= accumulator;
                OP_LB: begin
                    // Carga byte desde la dirección (solo 8 bits LSB de la palabra)
                    accumulator <= {{2{memory[{1'b0, operand[4:0]}][7]}}, memory[{1'b0, operand[4:0]}][7:0]};
                end
                OP_SB: begin
                    // Almacena byte (bits 7:0) en la dirección, manteniendo bits 9:8 intactos
                    memory[{1'b0, operand[4:0]}][7:0] <= accumulator[7:0];
                end
                
                // ---------- Pila (PUSH/POP) ----------
                // Se reutilizan dos de los códigos (podrían ser otros). 
                // En este ejemplo no están en la lista de 32, pero se pueden
                // añadir si se cambia algún opcode no usado.
                // Por ahora se omiten para mantener 32 exactos.
                
                // ---------- Saltos condicionales (comparación con inmediato) ----------
                OP_BEQ: if (accumulator == {{5{operand[4]}}, operand}) program_counter <= program_counter + {{5{operand[4]}}, operand};
                OP_BNE: if (accumulator != {{5{operand[4]}}, operand}) program_counter <= program_counter + {{5{operand[4]}}, operand};
                OP_BLT: if ($signed(accumulator) < $signed({{5{operand[4]}}, operand})) program_counter <= program_counter + {{5{operand[4]}}, operand};
                OP_BGE: if ($signed(accumulator) >= $signed({{5{operand[4]}}, operand})) program_counter <= program_counter + {{5{operand[4]}}, operand};
                
                // ---------- Saltos incondicionales y con enlace ----------
                OP_J:   program_counter <= {1'b0, operand};          // salto absoluto (dirección de 5 bits)
                OP_JAL: begin
                            link_reg <= program_counter;             // guarda siguiente dirección
                            program_counter <= {1'b0, operand};
                         end
                OP_JALR: begin
                            link_reg <= program_counter;
                            program_counter <= accumulator + {{5{operand[4]}}, operand};
                         end
                default: ; // nop
            endcase
        end
    end
end
endmodule
