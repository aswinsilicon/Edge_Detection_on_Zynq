`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2025 12:12:15
// Design Name: 
// Module Name: image_processing_top
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
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Create Date: 24.06.2025
// Design Name: 
// Module Name: image_processing_top
// Description: Top-level module for image processing pipeline with FIFO output buffer
//////////////////////////////////////////////////////////////////////////////////

module image_processing_top(

    input axi_clk,
    input axi_reset_n,  // active-low

    // slave interface (input)
    input in_data_valid,
    input [7:0] in_data,
    output out_data_ready,  // backpressure output to testbench

    // master interface (output)
    output out_data_valid,
    output [7:0] out_data,
    input in_data_ready,

    // interrupt
    output out_intr
);

    // Internal wires
    wire [71:0] pixel_data;
    wire pixel_data_valid;
    wire [7:0] convolved_data;
    wire convolved_data_valid;
    wire axis_prog_full;

    // Assign backpressure signal
    assign out_data_ready = !axis_prog_full;

    // Image control module: handles pixel windowing
    image_control imgc (
        .in_clk(axi_clk),
        .in_rst(!axi_reset_n), // active-high reset internally
        .in_pixel_data(in_data),
        .in_pixel_data_valid(in_data_valid),
        .out_pixel_data(pixel_data),
        .out_pixel_data_valid(pixel_data_valid),
        .out_intr(out_intr)
    );

    // MAC (convolution) block
    mac conv (
        .in_clk(axi_clk),
        .in_pixel_data(pixel_data),
        .in_pixel_data_valid(pixel_data_valid),
        .out_mac_data(convolved_data),
        .out_mac_data_valid(convolved_data_valid)
    );

    // FIFO buffer for output pixels
    outputBuff_fifo_generator outBuff (
        .wr_rst_busy(wr_rst_busy),
        .rd_rst_busy(rd_rst_busy),
        .s_aclk(axi_clk),
        .s_aresetn(axi_reset_n),                     // FIXED: proper FIFO reset
        .s_axis_tvalid(convolved_data_valid),
        .s_axis_tready(),                            // Not backpressured in this setup
        .s_axis_tdata(convolved_data),
        .m_axis_tvalid(out_data_valid),
        .m_axis_tready(in_data_ready),
        .m_axis_tdata(out_data),
        .axis_prog_full(axis_prog_full)
    );
    
    always @(posedge axi_clk) begin
    if (convolved_data_valid)
        $display("Writing to FIFO: %h", convolved_data);
    if (out_data_valid)
        $display("Reading from FIFO: %h", out_data);
end

endmodule

/*
module image_processing_top(

    input axi_clk,
    input axi_reset_n,  //active low
    
    //slave interface
    input in_data_valid,
    input [7:0] in_data,
    output out_data_ready,
    
    //master interface
    output  out_data_valid,
    output [7:0] out_data,
    input   in_data_ready,
    
    //interrupt
    output  out_intr
    );
    
    
    wire [71:0] pixel_data;
    wire pixel_data_valid;
    wire [7:0] convolved_data;
    wire convolved_data_valid;
    
    wire axis_prog_full;
    assign out_data_ready = !axis_prog_full;
    
    image_control imgc(
  
    .in_clk(axi_clk),
    .in_rst(!axi_reset_n),
    .in_pixel_data(in_data),
    .in_pixel_data_valid(in_data_valid),
    .out_pixel_data(pixel_data),
    .out_pixel_data_valid(pixel_data_valid),
    .out_intr(out_intr) 
    );
    
     
    mac conv(
 
    .in_clk(axi_clk),                 
    .in_pixel_data(pixel_data),    
    .in_pixel_data_valid(pixel_data_valid),
    .out_mac_data(convolved_data),
    .out_mac_data_valid(convolved_data_valid)
    );
    
    //FIFO generator
    //output is stored in FIFO and then moved out
    outputBuff_fifo_generator outBuff (
  .wr_rst_busy(wr_rst_busy),        // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy),        // output wire rd_rst_busy
  .s_aclk(axi_clk),                  // input wire s_aclk
  .s_aresetn(axi_reset_n),            // input wire s_aresetn
  .s_axis_tvalid(convolved_data_valid),    // input wire s_axis_tvalid
  .s_axis_tready(),    // output wire s_axis_tready
  .s_axis_tdata(convolved_data),          // input wire [7 : 0] s_axis_tdata
  .m_axis_tvalid(out_data_valid),    // output wire m_axis_tvalid
  .m_axis_tready(in_data_ready),    // input wire m_axis_tready
  .m_axis_tdata(out_data),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)   // output wire axis_prog_full 
   );
    
endmodule
*/