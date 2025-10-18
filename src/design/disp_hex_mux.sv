`timescale 1ns / 1ps
`include "../design/seven_seg_defs.sv" 

module  disp_hex_mux  ( 
  input   logic   clk,  rst_n,  
  input   logic  [3:0]  hex3, hex2 , hex1, hex0 , //  hex  digits  
  input   logic  [3:0]  dp_in ,   //  4  decimal   points  
  output  logic  [3:0]  an,       //  enable 1-out-of-4  asserted   low 
  output  logic  [7:0]  sseg      //  led   segments 
                         ); 
	//  constant   declaration  
	//  refreshing rate  around  800  Hz  (50  MH.z/2^16) 
	//localparam   N = 18 ; 
	//For faster simulation, comment prior and uncomment following
	localparam   N = 14; 
	//  internal   signal   declaration
                         
      logic    [N-1:0]  q_reg;  
      logic    [N-1:0]  q_next;  
      logic    [3:0]    hex_in;  
      logic    dp ;  
	//  N-bit  counter structurally coded  
	//  register  
 	always_ff@ ( posedge clk, posedge rst_n) 
         if  (rst_n) 
			q_reg  <=  '0 ;  
		 else  
        	q_reg  <=  q_next;
                        
	//  next state logic  
		assign   q_next  =  q_reg + 1; 
    logic    [1:0] sel;
    assign   sel= q_reg[N-1 -: 2];
  
  // This logic generates selection mux and anode control
  //  2  MSBs  of   counter   to   control   4-to-1   multiplexing  
  //  and  to generate active-low enable signal  
	 always @(*) begin
    case   (sel) //Testing the 2 MSBs from the counter 
		2'b00: 
 			begin  //Assuming an active_low anode 
				an      =  4'b1110; 
				hex_in  =  hex0; 
        dp      =  dp_in[0]; 
			end 
    2'b01: 
			begin  
				an      =  4'b1101; 
				hex_in  =  hex1; 
        dp      =  dp_in[1]; 
			end 
		2'b10: 
			begin  
				an     =  4'b1011; 
        hex_in =  hex2; 
        dp     =  dp_in[2] ; 
      end 
      default :  
          begin  
              an     =  4'b0111; 
              hex_in =  hex3; 
              dp     =  dp_in[3] ; 
          end 
      endcase 
   end
  
     // hex  to   seven-segment led   display
     // This logic implements the 7-seg decoder
  
     always @(*)  
       begin  
         case(hex_in) 
           4'h0 :  sseg[6:0]  =  `SS_0; 
           4'h1 :  sseg[6:0]  =  `SS_1; 
           4'h2 :  sseg[6:0]  =  `SS_2; 
           4'h3 :  sseg[6:0]  =  `SS_3; 
           4'h4 :  sseg[6:0]  =  `SS_4; 
           4'h5 :  sseg[6:0]  =  `SS_5; 
           4'h6 :  sseg[6:0]  =  `SS_6; 
           4'h7 :  sseg[6:0]  =  `SS_7; 
           4'h8 :  sseg[6:0]  =  `SS_8; 
           4'h9 :  sseg[6:0]  =  `SS_9; 
           4'ha :  sseg[6:0]  =  `SS_A;             
           4'hb :  sseg[6:0]  =  `SS_B; 
           4'hc :  sseg[6:0]  =  `SS_C; 
           4'hd :  sseg[6:0]  =  `SS_D; 
           4'he :  sseg[6:0]  =  `SS_E; 
           default : sseg [6:0]  = `SS_F;  // 4'hf  
         endcase  
         sseg[7]  =  dp; //Notice that this handles the decimal point
       end 
endmodule

module top_disp_hex(
    input  logic clk,       // reloj de 50 MHz en la FPGA
    input  logic rst_n,     // botón de rst_n activo en alto
    output logic [3:0] an,  // ánodos del display (activos en bajo)
    output logic [7:0] sseg // segmentos (activos en bajo)
);
    // ----------------------------------------------------
    // Instancia del display driver
    // ----------------------------------------------------
    disp_hex_mux disp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .hex3(hex3),
        .hex2(hex2),
        .hex1(hex1),
        .hex0(hex0),
        .dp_in(dp_in),
        .an(an),
        .sseg(sseg)
    );

endmodule
