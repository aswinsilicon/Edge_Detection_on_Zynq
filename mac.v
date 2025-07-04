`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2025 12:16:17
// Design Name: 
// Module Name: mac
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mac(
    input in_clk,
    input [71:0] in_pixel_data,
    input in_pixel_data_valid,
    output reg [7:0] out_mac_data,
    output reg out_mac_data_valid
);

    reg [7:0] kernel [8:0];
    integer i;

    reg [15:0] multData [8:0];       // kernel * pixel = 8 * 8 = 16-bit
    reg multDataValid;

    reg [19:0] sumDataInt;           // ? 9 * 16-bit = max 20-bit
    reg [19:0] sumData;
    reg sumDataValid;

    initial begin
        for (i = 0; i < 9; i = i + 1)
            kernel[i] = 1;
    end

    // Pipeline stage 1: Multiply
    always @(posedge in_clk) begin
        for (i = 0; i < 9; i = i + 1)
            multData[i] <= kernel[i] * in_pixel_data[i*8 +: 8];
        multDataValid <= in_pixel_data_valid;
    end

    // Combinational Sum
    always @(*) begin
        sumDataInt = 0;
        for (i = 0; i < 9; i = i + 1)
            sumDataInt = sumDataInt + multData[i];
    end

    // Pipeline stage 2: Register sum
    always @(posedge in_clk) begin
        sumData <= sumDataInt;
        sumDataValid <= multDataValid;
    end

    // Pipeline stage 3: Final output
    always @(posedge in_clk) begin
        out_mac_data <= sumData / 9;
        out_mac_data_valid <= sumDataValid;
    end

endmodule

/*
module mac(
 
    input in_clk,                 //input clock
    input [71:0] in_pixel_data,   //24 x 3-lineBuffers =72 pixels
    input in_pixel_data_valid,
    output reg [7:0] out_mac_data,
    output reg   out_mac_data_valid
    );
    
    reg [7:0] kernel [8:0]; //9 values (3x3) , 8-bit wide in case we need
    integer i;
    reg [15:0] multData[8:0];   //operands multiplication so width must be 16 bit
    reg multDataValid;
    reg sumDataInt;
    reg sumData;
    reg sumDataValid;
    
    
    //initializing kernel values
    initial
        begin
            for(i=0;i<9;i=i+1)      //equivalent to kernel=0, kernel=1
                begin
                     kernel[i] = 1;  //making an identity matrix
                end    
        end   
        
     //first pipelining   
    //multipication of pixels and kernels
    always @(posedge in_clk)
    begin
        for(i=0;i<9;i=i+1)
            begin
                multData[i] <= kernel[i]*in_pixel_data[i*8+:8];
            end
                multDataValid <= in_pixel_data_valid;
    end 
    
    //addition : modelled as a combinational circuit using always block
    //here using a non-procedural assignment does not give us accurate outputs 
    //it is not possible to get outputs during simulation and synthesis phases
    
    
    always @(*)
    begin
        sumDataInt = 0;
        for(i=0;i<9;i=i+1)
            begin
                sumDataInt = sumDataInt + multData[i];
            end
    end
    
    //second pipelining
    always @(posedge in_clk)
    begin
        sumData <= sumDataInt;
        sumDataValid <= multDataValid;
    end 
    
    //third pipelining with final result
    always @(posedge in_clk)
    begin
        out_mac_data <= sumData/9;
        out_mac_data_valid <= sumDataValid;
    end
    
endmodule
*/