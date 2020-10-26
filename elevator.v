module main;
  
  reg clk;
  reg rst_n;
  reg [31:0] new_floor_requests;
  wire [2:0] elevator_state;
  wire [4:0] current_floor;

initial begin
  repeat (5) begin
    $display("Hello, World!");
  end
end

  initial begin
    clk=0;
    forever begin
      #5; clk = ~clk;
    end
  end
  
  initial begin
    rst_n=0;
    new_floor_requests = 32'h00000000;
    #30;
    rst_n=1;
    #20;
    #5;
    new_floor_requests[22]=1;
    new_floor_requests[13]=1;
    new_floor_requests[2]=1;
    #10;
    new_floor_requests = 32'h00000000;
    #200;
    new_floor_requests[1]=1;
    #10;
    new_floor_requests = 32'h00000000;
    #400;
    $finish;
  end
  
  elevator elavator ( .*);
  
  always @(posedge clk) begin
    $display("Elevator is : ", elevator_state, " at " , current_floor, " floor");
  end
  
endmodule

  
module elevator(
  input        clk,
  input        rst_n,
  input [31:0] new_floor_requests,
  output [2:0] elevator_state,
  output [4:0] current_floor
);
  
  
  `define IDLE 3'b000
  `define MOVING_UP 3'b001
  `define MOVING_DOWN 3'b010
  `define STOPPED_WHILE_MOVING_UP 3'b011
  `define STOPPED_WHILE_MOVING_DOWN 3'b100
  
  reg [2:0]  elevator_state;
  reg [2:0]  next_elevator_state;
  reg [31:0] floor_requests;   // Bitwise indicator of floor requests
  reg [4:0]  current_floor;    // Current Floor
  
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      elevator_state <= `IDLE;
      floor_requests <= 32'h00000000;
      current_floor <= 5'h00;
    end else begin
      elevator_state <= next_elevator_state;
      floor_requests <= (floor_requests | new_floor_requests) &
                           (~(1 << current_floor));
      if (elevator_state == `MOVING_UP) begin
        current_floor <= current_floor+1;
      end else if (elevator_state == `MOVING_DOWN) begin
        current_floor <= current_floor-1;
      end
    end
  end
  
  always @(*) begin
    case (elevator_state)
      `IDLE : begin
        if ( | floor_requests ) begin
          if ( requests_above_floor[current_floor] ) begin
            next_elevator_state = `MOVING_UP;
          end else begin
            next_elevator_state = `MOVING_DOWN;
          end
        end else next_elevator_state = `IDLE;
      end
      `MOVING_UP : begin
        if ( floor_requests[current_floor+1] ) begin
          next_elevator_state = `STOPPED_WHILE_MOVING_UP;
        end else begin
          next_elevator_state = `MOVING_UP;
        end
      end
      `STOPPED_WHILE_MOVING_UP: begin
        if ( requests_above_floor[current_floor] ) begin
          next_elevator_state = `MOVING_UP;
        end else begin
          next_elevator_state = `IDLE;
        end
      end
      `MOVING_DOWN: begin
        if ( floor_requests[current_floor-1] ) begin
          next_elevator_state = `STOPPED_WHILE_MOVING_DOWN;
        end else begin
          next_elevator_state = `MOVING_DOWN;
        end
      end
     `STOPPED_WHILE_MOVING_DOWN: begin
       if ( requests_below_floor[current_floor]) begin
          next_elevator_state = `MOVING_DOWN;
        end else begin
          next_elevator_state = `IDLE;
        end
      end
      default : begin
        next_elevator_state = `IDLE;
      end
    endcase
  end

      
  wire [31:0] requests_above_floor;
  wire [31:0] requests_below_floor;
      
  assign requests_above_floor[31] = 0;  
  genvar i;
  generate 
  for (i=0; i<30; i=i+1) begin
    assign requests_above_floor[i] = | floor_requests[31:i+1];
  end
  endgenerate
      
  assign requests_below_floor[0] = 0;
  generate 
  for (i=1; i<31; i=i+1) begin
    assign requests_below_floor[i] = | floor_requests[i-1:0];
  end
  endgenerate
            
endmodule
