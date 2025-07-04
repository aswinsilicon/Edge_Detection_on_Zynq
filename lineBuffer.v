`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2025 10:23:18
// Design Name: 
// Module Name: lineBuffer
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


module lineBuffer(
    input in_clk,         //input clock
    input in_rst,         //active high reset
    input [7:0] in_data,    //8-bit input data (1 pixel of data) at a time to line buffer
    input in_data_valid,  //1-bit valid signal for data
    output [23:0] out_data, //24bit output data (3 pixels at a time)
    
    //output [7:0] out_data [2:0] is wrong syntax in Verilog
    input in_read_data        //control signal to indicate whether to write or read
    );
    
    reg [7:0] lineBuff [511:0]; //line buffer
    
    reg [8:0] writePointer; //indicate where to write on memory log(lineBuff)(base2)
    reg [8:0] readPointer;  //indicate where to read from memory log(lineBuff)(base2)
    
    always @(posedge in_clk)
        begin
            if(in_data_valid)
                lineBuff[writePointer] <= in_data;
        end
        
    //logic for increment in writePointer and resetting conditions
    always @(posedge in_clk)
    begin
        if(in_rst)
            writePointer <= 'd0;
        else if(in_data_valid)
            writePointer <= writePointer + 'd1;
    end
    
    //reading
    
    //combinational because sequential makes 1 clock latency
    assign out_data = {lineBuff[readPointer],lineBuff[readPointer+1],lineBuff[readPointer+2]};  
                       //24-bit out_data
    
    //logic for increment in readPointer and resetting conditions
     always @(posedge in_clk)
    begin
        if(in_rst)
            readPointer <= 'd0;
        else if(in_read_data)
            readPointer <= readPointer + 'd1;
    end
        
endmodule
