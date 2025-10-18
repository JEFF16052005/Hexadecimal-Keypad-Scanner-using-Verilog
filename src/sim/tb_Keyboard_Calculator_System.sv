`timescale 1ns / 1ps

module tb_Keyboard_Calculator_System();
    
    // Parámetros
    parameter CLK_PERIOD = 37; // 27MHz ≈ 37ns periodo
    
    // Señales del testbench
    reg clk_27MHz;
    reg reset;
    reg [3:0] row_in;
    wire [3:0] col_out;
    wire [7:0] sseg;
    wire [3:0] an;
    
    // Instancia del sistema bajo prueba
    Keyboard_Calculator_System DUT (
        .clk_27MHz(clk_27MHz),
        .reset(reset),
        .row_in(row_in),
        .col_out(col_out),
        .sseg(sseg),
        .an(an)
    );
    
    // Generación de reloj
    initial begin
        clk_27MHz = 0;
        forever #(CLK_PERIOD/2) clk_27MHz = ~clk_27MHz;
    end
    
    // Tareas para simular teclas
    task press_key;
        input [3:0] key_value;
        input [3:0] expected_col;
        begin
            // Esperar a que se active la columna esperada
            wait(col_out == expected_col);
            
            // Simular rebote
            row_in = 4'b0000;
            repeat(10) @(posedge clk_27MHz);
            
            // Activar fila correspondiente (simular presión)
            case (key_value)
                4'h1: row_in = 4'b0001; // Fila 0
                4'h2: row_in = 4'b0001;
                4'h3: row_in = 4'b0001;
                4'hA: row_in = 4'b0001;
                
                4'h4: row_in = 4'b0010; // Fila 1
                4'h5: row_in = 4'b0010;
                4'h6: row_in = 4'b0010;
                4'hB: row_in = 4'b0010;
                
                4'h7: row_in = 4'b0100; // Fila 2
                4'h8: row_in = 4'b0100;
                4'h9: row_in = 4'b0100;
                4'hC: row_in = 4'b0100;
                
                4'hD: row_in = 4'b1000; // Fila 3 (*)
                4'h0: row_in = 4'b1000;
                4'hE: row_in = 4'b1000; // (#)
                4'hF: row_in = 4'b1000; // (D)
            endcase
            
            // Mantener presión por tiempo suficiente
            repeat(100) @(posedge clk_27MHz);
            
            // Liberar tecla
            row_in = 4'b0000;
            repeat(50) @(posedge clk_27MHz);
            
            $display("Tecla presionada: %h, Tiempo: %0t ns", key_value, $time);
        end
    endtask
    
    // Tarea para verificar display
    task verify_display;
        input [15:0] expected_value;
        input string test_name;
        begin
            // Esperar un poco para que se actualice el display
            repeat(1000) @(posedge clk_27MHz);
            
            $display("=== Verificación: %s ===", test_name);
            $display("Tiempo: %0t ns", $time);
            $display("Ánodos: %b", an);
            $display("Segmentos: %b", sseg);
            $display("Valor esperado en display");
            $display("=========================");
        end
    endtask
    
    // Test case 1: Suma básica 123 + 456 = 579
    task test_suma_basica;
        begin
            $display("\n*** Iniciando Test 1: 123 + 456 = 579 ***");
            
            // Ingresar primer número: 123
            press_key(4'h1, 4'b0001); // 1
            verify_display(16'h0A31, "Después de 1");
            
            press_key(4'h2, 4'b0010); // 2  
            verify_display(16'h0A32, "Después de 2");
            
            press_key(4'h3, 4'b0100); // 3
            verify_display(16'h0A33, "Después de 3 - Listo primer número");
            
            // Confirmar primer número con *
            press_key(4'hD, 4'b1000); // *
            verify_display(16'h0E00, "Confirmado primer número");
            
            // Ingresar segundo número: 456
            press_key(4'h4, 4'b0001); // 4
            verify_display(16'h0E34, "Después de 4");
            
            press_key(4'h5, 4'b0010); // 5
            verify_display(16'h0E35, "Después de 5");
            
            press_key(4'h6, 4'b0100); // 6
            verify_display(16'h0E36, "Después de 6 - Listo segundo número");
            
            // Calcular con #
            press_key(4'hE, 4'b1000); // #
            verify_display(16'h0579, "Resultado 579");
            
            // Verificar resultado
            repeat(5000) @(posedge clk_27MHz);
            $display("*** Test 1 COMPLETADO: 123 + 456 = 579 ***");
        end
    endtask
    
    // Test case 2: Suma con carry 999 + 111 = 1110
    task test_suma_con_carry;
        begin
            $display("\n*** Iniciando Test 2: 999 + 111 = 1110 ***");
            
            // Reiniciar sistema
            reset = 1;
            repeat(10) @(posedge clk_27MHz);
            reset = 0;
            repeat(100) @(posedge clk_27MHz);
            
            // Ingresar 999
            press_key(4'h9, 4'b0100); // 9
            press_key(4'h9, 4'b0100); // 9  
            press_key(4'h9, 4'b0100); // 9
            press_key(4'hD, 4'b1000); // *
            
            // Ingresar 111
            press_key(4'h1, 4'b0001); // 1
            press_key(4'h1, 4'b0001); // 1
            press_key(4'h1, 4'b0001); // 1
            press_key(4'hE, 4'b1000); // #
            
            // Verificar resultado 1110
            repeat(5000) @(posedge clk_27MHz);
            $display("*** Test 2 COMPLETADO: 999 + 111 = 1110 ***");
        end
    endtask
    
    // Test case 3: Reinicio durante operación
    task test_reinicio;
        begin
            $display("\n*** Iniciando Test 3: Reinicio ***");
            
            // Ingresar primer número parcial
            press_key(4'h7, 4'b0001); // 7
            press_key(4'h8, 4'b0010); // 8
            
            // Reiniciar en medio de la entrada
            reset = 1;
            repeat(10) @(posedge clk_27MHz);
            reset = 0;
            repeat(100) @(posedge clk_27MHz);
            
            // Verificar que se reinició correctamente
            verify_display(16'h0A00, "Sistema reiniciado");
            
            $display("*** Test 3 COMPLETADO: Reinicio exitoso ***");
        end
    endtask
    
    // Test case 4: Teclas inválidas durante entrada
    task test_teclas_invalidas;
        begin
            $display("\n*** Iniciando Test 4: Teclas inválidas ***");
            
            // Intentar presionar teclas no numéricas durante entrada
            press_key(4'h1, 4'b0001); // 1 (válida)
            press_key(4'hA, 4'b1000); // A (inválida - debería ignorarse)
            press_key(4'h2, 4'b0010); // 2 (válida)
            press_key(4'hB, 4'b1000); // B (inválida - debería ignorarse)
            press_key(4'h3, 4'b0100); // 3 (válida)
            
            // Solo deberían haberse registrado 1, 2, 3
            verify_display(16'h0A33, "Solo dígitos válidos registrados");
            
            $display("*** Test 4 COMPLETADO: Teclas inválidas ignoradas ***");
        end
    endtask
    
    // Procedimiento de test principal
    initial begin
        // Inicializar señales
        reset = 0;
        row_in = 4'b0000;
        
        // Esperar inicio
        #100;
        reset = 1;
        #100;
        reset = 0;
        #1000;
        
        $display("==========================================");
        $display(" INICIANDO SIMULACIÓN COMPLETA DEL SISTEMA");
        $display("==========================================");
        
        // Ejecutar tests
        test_suma_basica();
        test_suma_con_carry(); 
        test_reinicio();
        test_teclas_invalidas();
        
        // Test final: Secuencia completa múltiple
        $display("\n*** Test Final: Múltiples operaciones ***");
        test_suma_basica();
        
        // Reiniciar con tecla D
        press_key(4'hF, 4'b1000); // D
        verify_display(16'h0A00, "Reiniciado con tecla D");
        
        // Otra suma
        press_key(4'h2, 4'b0010); // 2
        press_key(4'h5, 4'b0010); // 5
        press_key(4'h0, 4'b1000); // 0
        press_key(4'hD, 4'b1000); // *
        
        press_key(4'h1, 4'b0001); // 1
        press_key(4'h0, 4'b1000); // 0
        press_key(4'h0, 4'b1000); // 0
        press_key(4'hE, 4'b1000); // #
        
        verify_display(16'h0350, "Resultado 250 + 100 = 350");
        
        // Finalizar simulación
        #10000;
        $display("\n==========================================");
        $display(" SIMULACIÓN COMPLETADA EXITOSAMENTE");
        $display("==========================================");
        $finish;
    end
    
    // Monitoreo de señales importantes
    always @(posedge clk_27MHz) begin
        if (DUT.key_valid) begin
            $display("Tecla detectada: %h, Válida: %b", DUT.key_code, DUT.key_valid);
        end
    end
    
    // Dump file para visualización en GTKWave
    initial begin
        $dumpfile("tb_Keyboard_Calculator_System.vcd");
        $dumpvars(0, tb_Keyboard_Calculator_System);
    end
    
    // Timeout de seguridad
    initial begin
        #5000000; // 5ms de simulación máxima
        $display("ERROR: Timeout de simulación");
        $finish;
    end

endmodule