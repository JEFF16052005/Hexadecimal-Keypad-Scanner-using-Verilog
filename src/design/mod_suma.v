// Conversor BCD a Binario (3 dígitos)
module BCD_to_Binary (
    input [11:0] bcd_in,    // 3 dígitos BCD: {centenas, decenas, unidades}
    output reg [9:0] binary_out // Salida binaria (hasta 999)
);

    wire [3:0] units = bcd_in[3:0];
    wire [3:0] tens = bcd_in[7:4];
    wire [3:0] hundreds = bcd_in[11:8];
    
    always @(*) begin
        binary_out = (hundreds * 100) + (tens * 10) + units;
    end

endmodule

// Conversor Binario a BCD (hasta 4 dígitos)
module Binary_to_BCD (
    input [10:0] binary_in, 
    output reg [15:0] bcd_out // Salida BCD: {miles, centenas, decenas, unidades}
);

    integer i;
    reg [26:0] shift_reg; // 27 bits: 16 para BCD + 11 para binario
    
    always @(*) begin
        shift_reg = {16'b0, binary_in};
        
        for (i = 0; i < 11; i = i + 1) begin
            // Ajustar dígitos BCD
            if (shift_reg[15:12] > 4) 
                shift_reg[15:12] = shift_reg[15:12] + 3;
            if (shift_reg[19:16] > 4) 
                shift_reg[19:16] = shift_reg[19:16] + 3;
            if (shift_reg[23:20] > 4) 
                shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[27:24] > 4) 
                shift_reg[27:24] = shift_reg[27:24] + 3;
                
            // Shift left
            shift_reg = shift_reg << 1;
        end
        
        bcd_out = shift_reg[26:11];
    end

endmodule

// Módulo Sumador Binario
module Binary_Adder (
    input [9:0] num_a,      // Primer número binario (0-999)
    input [9:0] num_b,      // Segundo número binario (0-999)
    output reg [10:0] sum   // Resultado binario (0-1998)
);

    always @(*) begin
        sum = num_a + num_b;
    end

endmodule