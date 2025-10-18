module Top_Keypad_LED (
    input clock,
    input reset,
    input [3:0] Row,
    output [3:0] Col,
    output led
);

    // Señales internas
    wire S_Row;
    wire [3:0] Code;
    wire Valid;
    wire [3:0] Row_debounced;
    
    // Instanciación del debounce para cada fila
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : row_debounce
            Debounce debounce_inst (
                .clk(clock),
                .n_reset(~reset),  // Invertir reset si es necesario
                .button_in(Row[i]),
                .DB_out(Row_debounced[i])
            );
        end
    endgenerate
    
    // Instanciación del sincronizador con señales debounced
    Synchronizer sync (
        .Row(Row_debounced),
        .clock(clock),
        .reset(reset),
        .S_Row(S_Row)
    );
    
    // Instanciación del keypad con señales debounced
    mod_Hex_Keypad_Custom keypad (
        .Row(Row_debounced),
        .S_Row(S_Row),
        .clock(clock),
        .reset(reset),
        .Code(Code),
        .Valid(Valid),
        .Col(Col)
    );
    
    // Controlador LED mejorado con debounce
    reg led_internal;
    reg [23:0] counter;
    reg blinking;
    reg valid_prev;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            counter <= 0;
            blinking <= 0;
            led_internal <= 1'b1;  // LED apagado (asumiendo lógica negativa)
            valid_prev <= 1'b0;
        end else begin
            valid_prev <= Valid;
            
            // Detectar flanco de subida de Valid (tecla presionada)
            if (Valid && !valid_prev) begin
                // Iniciar parpadeo cuando se detecta tecla válida
                blinking <= 1'b1;
                counter <= 0;
                led_internal <= 1'b0;  // Encender LED inicialmente
            end else if (blinking) begin
                if (counter == 24'd6750000) begin  // ~0.25 segundos de parpadeo
                    blinking <= 1'b0;
                    led_internal <= 1'b1;  // Apagar LED
                end else begin
                    counter <= counter + 1;
                    // Parpadear más lento para mejor visibilidad
                    if (counter[20]) begin  // Parpadeo cada ~62ms
                        led_internal <= ~led_internal;
                    end
                end
            end else begin
                led_internal <= 1'b1;  // Mantener LED apagado
            end
        end
    end
    
    assign led = led_internal;

endmodule