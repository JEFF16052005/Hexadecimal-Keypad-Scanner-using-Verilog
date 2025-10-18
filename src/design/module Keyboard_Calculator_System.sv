module Keyboard_Calculator_System (
    input clk_27MHz,
    input reset,
    input [3:0] row_in,
    output [3:0] col_out,
    output [7:0] sseg,      // Cambiado a sseg para coincidir con el profesor
    output [3:0] an         // Cambiado a 4 bits para 4 displays
);

    // Estados de la FSM
    parameter STATE_INPUT_A    = 3'b000;
    parameter STATE_INPUT_B    = 3'b001;
    parameter STATE_SHOW_RESULT = 3'b010;
    
    // Señales internas
    wire [3:0] key_code;
    wire key_valid;
    wire debounced_valid;
    reg [2:0] current_state, next_state;
    reg [3:0] num_a [2:0];  // Primer número (3 dígitos BCD)
    reg [3:0] num_b [2:0];  // Segundo número (3 dígitos BCD)
    reg [2:0] digit_counter_a, digit_counter_b;
    
    // Señales para el display
    reg [3:0] hex3, hex2, hex1, hex0;  // 4 dígitos para el display
    reg [3:0] dp_in;                   // Puntos decimales
    
    // Señales para conversión y suma
    wire [11:0] bcd_a, bcd_b;
    wire [9:0] binary_a, binary_b;
    wire [10:0] binary_sum;
    wire [15:0] bcd_result;
    
    // Instanciación del teclado
    wire s_row_sync;
    wire [3:0] col_signal;
    
    Synchronizer sync_inst (
        .Row(row_in),
        .clock(clk_27MHz),
        .reset(reset),
        .S_Row(s_row_sync)
    );
    
    Hex_Keypad_Custom_4x4 keypad_inst (
        .Row(row_in),
        .S_Row(s_row_sync),
        .clock(clk_27MHz),
        .reset(reset),
        .Code(key_code),
        .Valid(key_valid),
        .Col(col_signal)
    );
    
    assign col_out = col_signal;
    
    // Debounce
    Debounce debounce_inst (
        .clk(clk_27MHz),
        .n_reset(~reset),
        .button_in(key_valid),
        .DB_out(debounced_valid)
    );
    
    // Convertir arrays a BCD
    assign bcd_a = {num_a[2], num_a[1], num_a[0]};
    assign bcd_b = {num_b[2], num_b[1], num_b[0]};
    
    // Conversión BCD a Binario
    BCD_to_Binary bcd2bin_a (
        .bcd_in(bcd_a),
        .binary_out(binary_a)
    );
    
    BCD_to_Binary bcd2bin_b (
        .bcd_in(bcd_b),
        .binary_out(binary_b)
    );
    
    // Suma binaria
    Binary_Adder adder_inst (
        .num_a(binary_a),
        .num_b(binary_b),
        .sum(binary_sum)
    );
    
    // Conversión Binario a BCD para display
    Binary_to_BCD bin2bcd_inst (
        .binary_in(binary_sum),
        .bcd_out(bcd_result)
    );
    
    // FSM
    always @(posedge clk_27MHz or posedge reset) begin
        if (reset) begin
            current_state <= STATE_INPUT_A;
            digit_counter_a <= 0;
            digit_counter_b <= 0;
            num_a[0] <= 4'd0; num_a[1] <= 4'd0; num_a[2] <= 4'd0;
            num_b[0] <= 4'd0; num_b[1] <= 4'd0; num_b[2] <= 4'd0;
        end else begin
            current_state <= next_state;
            
            if (debounced_valid) begin
                case (current_state)
                    STATE_INPUT_A: begin
                        if (key_code <= 4'd9 && digit_counter_a < 3) begin
                            // Desplazar dígitos (MSB first)
                            num_a[2] <= num_a[1];
                            num_a[1] <= num_a[0]; 
                            num_a[0] <= key_code;
                            digit_counter_a <= digit_counter_a + 1;
                        end
                        // Tecla '*' para confirmar primer número
                        else if (key_code == 4'hD && digit_counter_a == 3) begin
                            next_state = STATE_INPUT_B;
                        end
                    end
                    
                    STATE_INPUT_B: begin
                        if (key_code <= 4'd9 && digit_counter_b < 3) begin
                            // Desplazar dígitos (MSB first)
                            num_b[2] <= num_b[1];
                            num_b[1] <= num_b[0];
                            num_b[0] <= key_code;
                            digit_counter_b <= digit_counter_b + 1;
                        end
                        // Tecla '#' para confirmar segundo número
                        else if (key_code == 4'hE && digit_counter_b == 3) begin
                            next_state = STATE_SHOW_RESULT;
                        end
                    end
                    
                    STATE_SHOW_RESULT: begin
                        // Tecla 'D' para reiniciar
                        if (key_code == 4'hF) begin
                            next_state = STATE_INPUT_A;
                            digit_counter_a <= 0;
                            digit_counter_b <= 0;
                            num_a[0] <= 4'd0; num_a[1] <= 4'd0; num_a[2] <= 4'd0;
                            num_b[0] <= 4'd0; num_b[1] <= 4'd0; num_b[2] <= 4'd0;
                        end
                    end
                endcase
            end
        end
    end
    
    // Lógica de siguiente estado
    always @(*) begin
        next_state = current_state;
    end
    
    // Lógica de display - Adaptada para el módulo del profesor
    always @(*) begin
        // Por defecto, sin puntos decimales
        dp_in = 4'b1111;
        
        case (current_state)
            STATE_INPUT_A: begin
                hex3 = 4'd13;   // Mostrar '*' como indicador
                hex2 = num_a[2]; // Centenas
                hex1 = num_a[1]; // Decenas  
                hex0 = num_a[0]; // Unidades
                dp_in[0] = 1'b0; // Punto decimal en unidades
            end
            
            STATE_INPUT_B: begin
                hex3 = 4'd14;   // Mostrar '#' como indicador
                hex2 = num_b[2]; // Centenas
                hex1 = num_b[1]; // Decenas
                hex0 = num_b[0]; // Unidades
                dp_in[0] = 1'b0; // Punto decimal en unidades
            end
            
            STATE_SHOW_RESULT: begin
                // Extraer dígitos del resultado BCD
                hex3 = bcd_result[15:12]; // Miles (si los hay)
                hex2 = bcd_result[11:8];  // Centenas
                hex1 = bcd_result[7:4];   // Decenas
                hex0 = bcd_result[3:0];   // Unidades
                // Sin puntos decimales en resultado
            end
            
            default: begin
                hex3 = 4'd15; // Apagado
                hex2 = 4'd15; // Apagado
                hex1 = 4'd15; // Apagado
                hex0 = 4'd15; // Apagado
            end
        endcase
    end
    
    // Instanciación del display del profesor
    disp_hex_mux display_inst (
        .clk(clk_27MHz),
        .rst_n(~reset),        // El profesor usa reset activo bajo
        .hex3(hex3),
        .hex2(hex2),
        .hex1(hex1),
        .hex0(hex0),
        .dp_in(dp_in),
        .an(an),
        .sseg(sseg)
    );

endmodule