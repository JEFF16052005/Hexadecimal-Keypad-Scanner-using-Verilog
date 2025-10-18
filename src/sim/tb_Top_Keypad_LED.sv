`timescale 1ns / 1ps

module tb_Top_Keypad_LED();
    
    // Señales del testbench
    reg clock;
    reg reset;
    reg [3:0] Row;
    wire [3:0] Col;
    wire led;
    
    // Instanciación del módulo bajo prueba
    Top_Keypad_LED uut (
        .clock(clock),
        .reset(reset),
        .Row(Row),
        .Col(Col),
        .led(led)
    );
    
    // Generación de reloj
    always #5 clock = ~clock;  // 100 MHz clock (10ns period)
    
    // Tareas para simular pulsaciones de teclas
    task press_key;
        input [3:0] row_val;
        input [3:0] col_val;
        begin
            // Esperar a que el keypad escanee la columna correcta
            wait (Col == col_val);
            
            // Simular rebotes mecánicos
            Row = 4'b0000;
            #100000;  // 100us
            
            Row = row_val;
            #20000;   // 20us
            
            Row = 4'b0000;
            #30000;   // 30us
            
            Row = row_val;
            #40000;   // 40us
            
            Row = 4'b0000;
            #25000;   // 25us
            
            // Mantener tecla presionada (estado estable)
            Row = row_val;
            #5000000; // 5ms
            
            // Liberar tecla con rebotes
            Row = 4'b0000;
            #50000;   // 50us
            
            Row = row_val;
            #15000;   // 15us
            
            Row = 4'b0000;
            #35000;   // 35us
            
            // Estado final liberado
            Row = 4'b0000;
            #10000000; // 10ms entre pulsaciones
        end
    endtask
    
    // Test cases para diferentes teclas
    task test_key_1;  // Fila 0, Col 0
        begin
            $display("Testing Key '1' - Row[0], Col[0]");
            press_key(4'b0001, 4'b0001);
        end
    endtask
    
    task test_key_5;  // Fila 1, Col 1
        begin
            $display("Testing Key '5' - Row[1], Col[2]");
            press_key(4'b0010, 4'b0010);
        end
    endtask
    
    task test_key_A;  // Fila 0, Col 3
        begin
            $display("Testing Key 'A' - Row[0], Col[8]");
            press_key(4'b0001, 4'b1000);
        end
    endtask
    
    task test_key_0;  // Fila 3, Col 1
        begin
            $display("Testing Key '0' - Row[3], Col[2]");
            press_key(4'b1000, 4'b0010);
        end
    endtask
    
    task test_multiple_keys;
        begin
            $display("Testing multiple key presses...");
            
            // Presionar tecla 1
            press_key(4'b0001, 4'b0001);
            
            // Presionar tecla 5  
            press_key(4'b0010, 4'b0010);
            
            // Presionar tecla A
            press_key(4'b0001, 4'b1000);
            
            // Presionar tecla 0
            press_key(4'b1000, 4'b0010);
        end
    endtask
    
    task test_rapid_presses;
        begin
            $display("Testing rapid key presses...");
            
            // Presión rápida de varias teclas
            press_key(4'b0001, 4'b0001);  // Key 1
            #2000000;  // 2ms entre pulsaciones
            press_key(4'b0010, 4'b0010);  // Key 5
            #2000000;  // 2ms
            press_key(4'b0100, 4'b0100);  // Key 9
        end
    endtask
    
    // Monitoreo de señales
    initial begin
        $display("Time\tReset\tRow\tCol\tLED");
        $monitor("%t\t%b\t%b\t%b\t%b", 
                 $time, reset, Row, Col, led);
    end
    
    // Proceso principal de test
    initial begin
        // Inicializar señales
        clock = 0;
        reset = 1;
        Row = 4'b0000;
        
        // Secuencia de reset
        #100;
        reset = 0;
        #100;
        reset = 1;
        #1000;
        
        $display("Starting Keypad LED Testbench...");
        
        // Test 1: Tecla individual '1'
        test_key_1();
        
        // Test 2: Tecla individual '5'  
        test_key_5();
        
        // Test 3: Tecla 'A'
        test_key_A();
        
        // Test 4: Tecla '0'
        test_key_0();
        
        // Test 5: Múltiples teclas
        test_multiple_keys();
        
        // Test 6: Pulsaciones rápidas
        test_rapid_presses();
        
        // Test 7: Sin pulsaciones (LED debería estar apagado)
        $display("Testing no key press (LED should be off)");
        #50000000; // 50ms
        
        // Finalizar simulación
        $display("All tests completed!");
        $finish;
    end
    
    // Verificaciones automáticas
    reg [31:0] key_press_count = 0;
    reg [31:0] led_blink_count = 0;
    reg [31:0] current_blinks;
    
    // Contar pulsaciones de teclas válidas
    always @(posedge uut.Valid) begin
        key_press_count <= key_press_count + 1;
        $display("Key press detected! Total: %d", key_press_count + 1);
    end
    
    // Contar parpadeos del LED
    reg led_prev = 1;
    always @(posedge clock) begin
        if (led !== led_prev && led === 0) begin // Detectar encendido del LED
            led_blink_count <= led_blink_count + 1;
            $display("LED turned ON - Blink count: %d", led_blink_count + 1);
        end
        led_prev <= led;
    end
    
    // Verificar que cada tecla válida genera un parpadeo
    always @(posedge uut.Valid) begin
        current_blinks = led_blink_count;
        // Esperar un tiempo y verificar que el LED parpadeó
        #1000000; // 1ms
        if (led_blink_count > current_blinks) begin
            $display("PASS: Key press generated LED blink");
        end else begin
            $display("ERROR: Key press did not generate LED blink");
        end
    end
    
    // Dump file para visualización en GTKWave
    initial begin
        $dumpfile("keypad_led.vcd");
        $dumpvars(0, tb_Top_Keypad_LED);
    end
    
endmodule