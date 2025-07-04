`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2025 09:43:19
// Design Name: 
// Module Name: image_control
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

module image_control(
    input in_clk,
    input in_rst,
    input [7:0] in_pixel_data,
    input in_pixel_data_valid,
    output reg [71:0] out_pixel_data,
    output out_pixel_data_valid,
    output reg out_intr
);

    reg [8:0] pixelCounter;
    reg [1:0] currentWriteLineBuffer;
    reg [3:0] lineBuffDataValid;

    reg [1:0] currentReadLineBuffer;
    wire [23:0] lb0data, lb1data, lb2data, lb3data;

    reg [8:0] readCounter;
    reg read_line_buffer;
    reg [3:0] lineBuffReadData;
    reg [11:0] total_pixelCounter;
    reg readState;

    localparam IDLE = 1'b0,
               RD_BUFFER = 1'b1;

    assign out_pixel_data_valid = read_line_buffer;

    // Pixel Counter (up to 512)
    always @(posedge in_clk) begin
        if (in_rst)
            pixelCounter <= 0;
        else if (in_pixel_data_valid)
            pixelCounter <= pixelCounter + 1;
    end

    // Line Buffer Switch Logic
    always @(posedge in_clk) begin
        if (in_rst)
            currentWriteLineBuffer <= 0;
        else if (pixelCounter == 511 && in_pixel_data_valid)
            currentWriteLineBuffer <= currentWriteLineBuffer + 1;
    end

    // Corrected: Valid signal for writing to line buffer
    always @(*) begin
        lineBuffDataValid = 4'b0000;
        if (in_pixel_data_valid)
            lineBuffDataValid[currentWriteLineBuffer] = 1'b1;
    end

    // Pixel counter for deciding when to switch to read mode
    always @(posedge in_clk) begin
        if (in_rst)
            total_pixelCounter <= 0;
        else if (in_pixel_data_valid && !read_line_buffer)
            total_pixelCounter <= total_pixelCounter + 1;
        else if (!in_pixel_data_valid && read_line_buffer)
            total_pixelCounter <= total_pixelCounter - 1;
    end

    // FSM to switch between IDLE and READING
    always @(posedge in_clk) begin
        if (in_rst) begin
            readState <= IDLE;
            read_line_buffer <= 1'b0;
            out_intr <= 1'b0;
        end else begin
            case (readState)
                IDLE: begin
                    out_intr <= 1'b0;
                    if (total_pixelCounter >= 1536) begin
                        read_line_buffer <= 1'b1;
                        readState <= RD_BUFFER;
                    end
                end
                RD_BUFFER: begin
                    if (readCounter == 511) begin
                        read_line_buffer <= 1'b0;
                        readState <= IDLE;
                        out_intr <= 1'b1;
                        readCounter <= 0; // ? fix: reset readCounter
                    end
                end
            endcase
        end
    end

    // Read Counter
    always @(posedge in_clk) begin
        if (in_rst)
            readCounter <= 0;
        else if (read_line_buffer)
            readCounter <= readCounter + 1;
    end

    // Read Line Buffer Selector
    always @(posedge in_clk) begin
        if (in_rst)
            currentReadLineBuffer <= 0;
        else if (readCounter == 511 && read_line_buffer)
            currentReadLineBuffer <= currentReadLineBuffer + 1;
    end

    // Output pixel window selection
    always @(*) begin
        case (currentReadLineBuffer)
            0: out_pixel_data = {lb2data, lb1data, lb0data};
            1: out_pixel_data = {lb3data, lb2data, lb1data};
            2: out_pixel_data = {lb0data, lb3data, lb2data};
            3: out_pixel_data = {lb1data, lb0data, lb3data};
        endcase
    end

    // Read enable logic for line buffers
    always @(*) begin
        case (currentReadLineBuffer)
            0: lineBuffReadData = {1'b0, read_line_buffer, read_line_buffer, read_line_buffer};
            1: lineBuffReadData = {read_line_buffer, read_line_buffer, read_line_buffer, 1'b0};
            2: lineBuffReadData = {read_line_buffer, 1'b0, read_line_buffer, read_line_buffer};
            3: lineBuffReadData = {read_line_buffer, read_line_buffer, 1'b0, read_line_buffer};
        endcase
    end

    // Instantiate line buffers
    lineBuffer lB0(.in_clk(in_clk), .in_rst(in_rst), .in_data(in_pixel_data),
                   .in_data_valid(lineBuffDataValid[0]), .out_data(lb0data),
                   .in_read_data(lineBuffReadData[0]));
    lineBuffer lB1(.in_clk(in_clk), .in_rst(in_rst), .in_data(in_pixel_data),
                   .in_data_valid(lineBuffDataValid[1]), .out_data(lb1data),
                   .in_read_data(lineBuffReadData[1]));
    lineBuffer lB2(.in_clk(in_clk), .in_rst(in_rst), .in_data(in_pixel_data),
                   .in_data_valid(lineBuffDataValid[2]), .out_data(lb2data),
                   .in_read_data(lineBuffReadData[2]));
    lineBuffer lB3(.in_clk(in_clk), .in_rst(in_rst), .in_data(in_pixel_data),
                   .in_data_valid(lineBuffDataValid[3]), .out_data(lb3data),
                   .in_read_data(lineBuffReadData[3]));

endmodule

/*
module image_control(
  
    input in_clk,
    input in_rst,
    input [7:0] in_pixel_data,
    input in_pixel_data_valid,
    output reg [71:0] out_pixel_data,
    output out_pixel_data_valid,
    output reg out_intr
    );
    
    reg [8:0] pixelCounter;
    reg [1:0] currentWriteLineBuffer; //as we have 4 line buffers
    reg [3:0] lineBuffDataValid;
    
    reg [1:0] currentReadLineBuffer; //reading in the current line buffer
    wire [23:0] lb0data;
    wire [23:0] lb1data;
    wire [23:0] lb2data;
    wire [23:0] lb3data;
    
    reg [8:0] readCounter;
    reg read_line_buffer;      //signal which ultimately tells from which line buffer we are reading
    reg [3:0] lineBuffReadData;
    reg [11:0] total_pixelCounter; //maximum 2000 count
    
    reg readState;
    
    localparam IDLE = 'b0,
           RD_BUFFER = 'b1;

     assign out_pixel_data_valid = read_line_buffer; 
    

    //logic for counting upto 512 for a line buffer so that it goes to the next line buffer
    //this is done for filling the data
    always @(posedge in_clk)
    begin
        if(in_rst)
            pixelCounter <= 0;
        else 
        begin
            if(in_pixel_data_valid)
                pixelCounter <= pixelCounter + 1;
        end
    end
    
    
    //logic for changing the line buffer once a 512 pixel data is received for a line buffer
    always @(posedge in_clk)
    begin
        if(in_rst)
            currentWriteLineBuffer <= 0;
        else
        begin
            if(pixelCounter == 511 & in_pixel_data_valid)
                currentWriteLineBuffer <= currentWriteLineBuffer+1;
        end
    end
    
    //validating such that pixel data gets written into the appropriate line buffer
    always @(*)
    begin
        lineBuffDataValid = 4'h0;
        lineBuffDataValid[currentWriteLineBuffer] = in_pixel_data;
    end
    
    
    
    
    //after writing in 3 line buffers completely (in our case 512 * 3 = 1536 pixel data),
    //we can start reading 
    
    //also we need to increment total_pixelCounter when we want to write 
    always @(posedge in_clk)
    begin
        if(in_rst)
            total_pixelCounter <= 0;
        else
        begin
            //if writing on the line buffer
            if(in_pixel_data_valid & !read_line_buffer)       //writing data from external world and not reading
                total_pixelCounter <= total_pixelCounter + 1;
                
            //if reading from the line buffer
            else if(!in_pixel_data_valid & read_line_buffer) //reading data and not taking 
                total_pixelCounter <= total_pixelCounter - 1;
       end
    end
    
    //STATE MACHINE
    //this controls the read operations in the line buffers
    always @(posedge in_clk)
    begin
        if(in_rst)
        begin
            readState <= IDLE;
            read_line_buffer <= 1'b0;
            out_intr <= 1'b0;
        end
        
        else
        begin
        case(readState)
            IDLE:begin
                    out_intr <= 1'b0;
                    if(total_pixelCounter >= 1536)
                        begin
                            read_line_buffer <= 1'b1; //reading started
                            readState <= RD_BUFFER;   //go to read buffer state
                        end 
                 end
            RD_BUFFER:begin
                if(readCounter == 511)               //read until readCounter = 511
                begin
                    readState <= IDLE;
                    read_line_buffer <= 1'b0;        //reading finished
                    out_intr <= 1'b1;
                end
            end
        endcase
    end
    end
    
    
    
    
    //read counter logic
    always @(posedge in_clk)
    begin
        if(in_rst)
            readCounter <= 0;
        else 
        begin
            if(read_line_buffer)
                readCounter <= readCounter + 1;
        end
    end
    
    //logic for controlling the currentReadLineBuffer
    //similar to currentWriteLineBuffer
    always @(posedge in_clk)
    begin
        if(in_rst)
            currentReadLineBuffer <= 0;
        else
        begin
            if(readCounter == 511 & read_line_buffer)  //read_line_buffer: 512th bit
                currentReadLineBuffer <= currentReadLineBuffer+1;
        end
    end
    
    //reading data logics (defined only source)
    always @(*)
    begin
        case(currentReadLineBuffer)
        0: begin
               out_pixel_data ={lb2data,lb1data,lb0data}; 
           end
        1: begin
               out_pixel_data ={lb3data,lb2data,lb1data}; 
           end
        2: begin
               out_pixel_data ={lb0data,lb3data,lb2data}; 
           end
        3: begin
               out_pixel_data ={lb1data,lb0data,lb3data}; 
           end
        endcase
        
    end
    
    //logic for switching read line buffer operations smoothly (how to read the data)
    //writing logics for read enable for particular line Buffers from which we are reading the data
    always @(*)
    begin
        case(currentReadLineBuffer)
        0: begin
                lineBuffReadData[0] = read_line_buffer;
                lineBuffReadData[1] = read_line_buffer;
                lineBuffReadData[2] = read_line_buffer;
                lineBuffReadData[3] = 1'b0;
           end
        1: begin
                lineBuffReadData[0] = 1'b0;
                lineBuffReadData[1] = read_line_buffer;
                lineBuffReadData[2] = read_line_buffer;
                lineBuffReadData[3] = read_line_buffer;
           end
        2: begin
                lineBuffReadData[0] = read_line_buffer;
                lineBuffReadData[1] = 1'b0;
                lineBuffReadData[2] = read_line_buffer;
                lineBuffReadData[3] = read_line_buffer;
           end
        3: begin
                lineBuffReadData[0] = read_line_buffer;
                lineBuffReadData[1] = read_line_buffer;
                lineBuffReadData[2] = 1'b0;
                lineBuffReadData[3] = read_line_buffer;
           end
        endcase
    end
    
    
    
    
    //for performance improvement we will be using 4 line buffers (instantiation)
    lineBuffer lB0(
    .in_clk(in_clk),         
    .in_rst(in_rst),         
    .in_data(in_pixel_data),   
    .in_data_valid(lineBuffDataValid[0]),  
    .out_data(lb0data), 
    .in_read_data(lineBuffReadData[0]) );
    
    lineBuffer lB1(
    .in_clk(in_clk),         
    .in_rst(in_rst),         
    .in_data(in_pixel_data),   
    .in_data_valid(lineBuffDataValid[1]),  
    .out_data(lb1data), 
    .in_read_data(lineBuffReadData[1]) );
    
    lineBuffer lB2(
    .in_clk(in_clk),         
    .in_rst(in_rst),         
    .in_data(in_pixel_data),   
    .in_data_valid(lineBuffDataValid[2]),  
    .out_data(lb2data), 
    .in_read_data(lineBuffReadData[2]) );
    
    lineBuffer lB3(
    .in_clk(in_clk),         
    .in_rst(in_rst),         
    .in_data(in_pixel_data),   
    .in_data_valid(lineBuffDataValid[3]),  
    .out_data(lb3data), 
    .in_read_data(lineBuffReadData[3]) );
    
  
endmodule
*/