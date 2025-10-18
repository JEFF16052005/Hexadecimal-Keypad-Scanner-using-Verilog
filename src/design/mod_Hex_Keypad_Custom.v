module Hex_Keypad_Custom_4x4 (
    input [3:0] Row,
    input S_Row,
    input clock,
    input reset,
    output reg [3:0] Code,
    output Valid,   
    output reg [3:0] Col
);
    
    reg [5:0] state, next_state;
    
    // One-hot encoding
    parameter S_0 = 6'b000001, S_1 = 6'b000010, S_2 = 6'b000100;
    parameter S_3 = 6'b001000, S_4 = 6'b010000, S_5 = 6'b100000;
    
    assign Valid = ((state == S_1) || (state == S_2) || (state == S_3) || (state == S_4)) && (Row != 0);
    
    // Decoding for your specific keypad layout:
    // 1  2  3  A   -> Row0: 1(1), 2(2), 3(3), A(10)
    // 4  5  6  B   -> Row1: 4(4), 5(5), 6(6), B(11)  
    // 7  8  9  C   -> Row2: 7(7), 8(8), 9(9), C(12)
    // *  0  #  D   -> Row3: *(13), 0(0), #(14), D(15)
    
    always @ (Row or Col) begin
        case ({Row, Col})
            // Row 0
            8'b0001_0001: Code = 4'h1;  // 1
            8'b0001_0010: Code = 4'h2;  // 2
            8'b0001_0100: Code = 4'h3;  // 3
            8'b0001_1000: Code = 4'hA;  // A
            
            // Row 1  
            8'b0010_0001: Code = 4'h4;  // 4
            8'b0010_0010: Code = 4'h5;  // 5
            8'b0010_0100: Code = 4'h6;  // 6
            8'b0010_1000: Code = 4'hB;  // B
            
            // Row 2
            8'b0100_0001: Code = 4'h7;  // 7
            8'b0100_0010: Code = 4'h8;  // 8
            8'b0100_0100: Code = 4'h9;  // 9
            8'b0100_1000: Code = 4'hC;  // C
            
            // Row 3
            8'b1000_0001: Code = 4'hD;  // * (CONFIRMAR PRIMER NÚMERO)
            8'b1000_0010: Code = 4'h0;  // 0
            8'b1000_0100: Code = 4'hE;  // # (CONFIRMAR SEGUNDO NÚMERO)
            8'b1000_1000: Code = 4'hF;  // D (RESET/REINICIAR)
            
            default: Code = 4'h0;       // No key pressed
        endcase
    end
    
    // State machine for column scanning (same as original)
    always @(posedge clock or posedge reset) begin
        if (reset) 
            state <= S_0;
        else 
            state <= next_state;
    end
    
    always @(state or S_Row or Row) begin
        next_state = state;
        Col = 0;
        
        case (state)
            // Assert all columns
            S_0: begin 
                Col = 4'b1111; 
                if (S_Row) 
                    next_state = S_1; 
            end
            
            // Assert column 0
            S_1: begin 
                Col = 4'b0001; 
                if (Row != 0) 
                    next_state = S_5; 
                else 
                    next_state = S_2; 
            end
            
            // Assert column 1
            S_2: begin 
                Col = 4'b0010; 
                if (Row != 0) 
                    next_state = S_5; 
                else 
                    next_state = S_3; 
            end
            
            // Assert column 2
            S_3: begin 
                Col = 4'b0100; 
                if (Row != 0) 
                    next_state = S_5; 
                else 
                    next_state = S_4; 
            end
            
            // Assert column 3
            S_4: begin 
                Col = 4'b1000; 
                if (Row != 0) 
                    next_state = S_5; 
                else 
                    next_state = S_0; 
            end
            
            // Wait for key release
            S_5: begin 
                Col = 4'b1111; 
                if (Row == 0) 
                    next_state = S_0; 
            end
        endcase
    end
endmodule