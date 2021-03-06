import constants::*;
import wires::*;
import functions::*;

module decode_stage
(
  input logic rst,
  input logic clk,
  input decoder_out_type decoder_out,
  output decoder_in_type decoder_in,
  input compress_out_type compress_out,
  output compress_in_type compress_in,
  input agu_out_type agu_out,
  output agu_in_type agu_in,
  input bcu_out_type bcu_out,
  output bcu_in_type bcu_in,
  input register_out_type register_out,
  output register_read_in_type register_rin,
  input csr_out_type csr_out,
  output csr_decode_in_type csr_din,
  input forwarding_out_type forwarding_out,
  output forwarding_register_in_type forwarding_rin,
  output mem_in_type storebuffer_in,
  input decode_in_type a,
  input decode_in_type d,
  output decode_out_type y,
  output decode_out_type q
);
  timeunit 1ns;
  timeprecision 1ps;

  decode_reg_type r,rin = init_decode_reg;
  decode_reg_type v = init_decode_reg;

  always_comb begin

    v = r;

    v.pc = d.f.pc;
    v.instr = d.f.instr;
    v.exception = d.f.exception;
    v.ecause = d.f.ecause;
    v.etval = d.f.etval;

    // if ((d.d.stall | d.e.stall) == 1) begin
    //   v = r;
    // end

    v.clear = d.d.jump | d.d.exception | d.d.mret | d.e.clear;

    v.stall = 0;

    v.waddr = v.instr[11:7];
    v.raddr1 = v.instr[19:15];
    v.raddr2 = v.instr[24:20];
    v.caddr = v.instr[31:20];

    decoder_in.instr = v.instr;

    v.imm = decoder_out.imm;
    v.wren = decoder_out.wren;
    v.rden1 = decoder_out.rden1;
    v.rden2 = decoder_out.rden2;
    v.cwren = decoder_out.cwren;
    v.crden = decoder_out.crden;
    v.auipc = decoder_out.auipc;
    v.lui = decoder_out.lui;
    v.jal = decoder_out.jal;
    v.jalr = decoder_out.jalr;
    v.branch = decoder_out.branch;
    v.load = decoder_out.load;
    v.store = decoder_out.store;
    v.nop = decoder_out.nop;
    v.csregister = decoder_out.csregister;
    v.division = decoder_out.division;
    v.multiplication = decoder_out.multiplication;
    v.bitmanipulation = decoder_out.bitmanipulation;
    v.alu_op = decoder_out.alu_op;
    v.bcu_op = decoder_out.bcu_op;
    v.lsu_op = decoder_out.lsu_op;
    v.csr_op = decoder_out.csr_op;
    v.div_op = decoder_out.div_op;
    v.mul_op = decoder_out.mul_op;
    v.bit_op = decoder_out.bit_op;
    v.fence = decoder_out.fence;
    v.ecall = decoder_out.ecall;
    v.ebreak = decoder_out.ebreak;
    v.mret = decoder_out.mret;
    v.wfi = decoder_out.wfi;
    v.valid = decoder_out.valid;

    compress_in.instr = v.instr;

    if (compress_out.valid == 1) begin
      v.imm = compress_out.imm;
      v.waddr = compress_out.waddr;
      v.raddr1 = compress_out.raddr1;
      v.raddr2 = compress_out.raddr2;
      v.wren = compress_out.wren;
      v.rden1 = compress_out.rden1;
      v.rden2 = compress_out.rden2;
      v.lui = compress_out.lui;
      v.jal = compress_out.jal;
      v.jalr = compress_out.jalr;
      v.branch = compress_out.branch;
      v.load = compress_out.load;
      v.store = compress_out.store;
      v.alu_op = compress_out.alu_op;
      v.bcu_op = compress_out.bcu_op;
      v.lsu_op = compress_out.lsu_op;
      v.ebreak = compress_out.ebreak;
      v.valid = compress_out.valid;
    end

    v.npc = v.pc + ((v.instr[1:0] == 2'b11) ? 4 : 2);

    register_rin.rden1 = v.rden1;
    register_rin.rden2 = v.rden2;
    register_rin.raddr1 = v.raddr1;
    register_rin.raddr2 = v.raddr2;

    forwarding_rin.rden1 = v.rden1;
    forwarding_rin.rden2 = v.rden2;
    forwarding_rin.raddr1 = v.raddr1;
    forwarding_rin.raddr2 = v.raddr2;
    forwarding_rin.rdata1 = register_out.rdata1;
    forwarding_rin.rdata2 = register_out.rdata2;

    v.rdata1 = forwarding_out.data1;
    v.rdata2 = forwarding_out.data2;

    bcu_in.rdata1 = v.rdata1;
    bcu_in.rdata2 = v.rdata2;
    bcu_in.bcu_op = v.bcu_op;

    v.jump = v.jal | v.jalr | bcu_out.branch;

    agu_in.rdata1 = v.rdata1;
    agu_in.imm = v.imm;
    agu_in.pc = v.pc;
    agu_in.auipc = v.auipc;
    agu_in.jal = v.jal;
    agu_in.jalr = v.jalr;
    agu_in.branch = v.branch;
    agu_in.load = v.load;
    agu_in.store = v.store;
    agu_in.lsu_op = v.lsu_op;

    v.address = agu_out.address;
    v.byteenable = agu_out.byteenable;
    v.exception = agu_out.exception;
    v.ecause = agu_out.ecause;
    v.etval = agu_out.etval;

    if (v.exception == 1) begin
      if (v.load == 1) begin
        v.load = 0;
        v.wren = 0;
      end else if (v.store == 1) begin
        v.store = 0;
      end else if (v.jump == 1) begin
        v.jump = 0;
        v.wren = 0;
      end else begin
        v.exception = 0;
      end
    end

    if (v.valid == 0) begin
      v.exception = 1;
      v.ecause = except_illegal_instruction;
      v.etval = v.instr;
    end else if (v.ebreak == 1) begin
      v.exception = 1;
      v.ecause = except_breakpoint;
      v.etval = v.instr;
    end else if (v.ecall == 1) begin
      v.exception = 1;
      v.ecause = except_env_call_mach;
      v.etval = v.instr;
    end

    if (d.d.cwren == 1) begin
      v.stall = 1;
    end else if (d.d.division == 1) begin
      v.stall = 1;
    end else if (d.d.bitmanipulation == 1 && d.d.bit_op.bmcycle == 1) begin
      v.stall = 1;
    end

    if ((v.stall | a.e.stall | v.clear | csr_out.exception | csr_out.mret) == 1) begin
      v.wren = 0;
      v.cwren = 0;
      v.auipc = 0;
      v.lui = 0;
      v.jal = 0;
      v.jalr = 0;
      v.branch = 0;
      v.load = 0;
      v.store = 0;
      v.nop = 0;
      v.csregister = 0;
      v.division = 0;
      v.multiplication = 0;
      v.bitmanipulation = 0;
      v.fence = 0;
      v.ecall = 0;
      v.ebreak = 0;
      v.mret = 0;
      v.wfi = 0;
      v.valid = 0;
      v.jump = 0;
      v.exception = 0;
    end

    if (v.clear == 1) begin
      v.stall = 0;
    end

    storebuffer_in.mem_valid = v.load | v.store | v.fence;
    storebuffer_in.mem_fence = v.fence;
    storebuffer_in.mem_instr = 0;
    storebuffer_in.mem_addr = v.address;
    storebuffer_in.mem_wdata = store_data(v.rdata2,v.lsu_op.lsu_sb,v.lsu_op.lsu_sh,v.lsu_op.lsu_sw);
    storebuffer_in.mem_wstrb = (v.load == 1) ? 4'h0 : v.byteenable;

    csr_din.crden = v.crden;
    csr_din.craddr = v.caddr;

    v.cdata = csr_out.cdata;

    rin = v;

    y.pc = v.pc;
    y.npc = v.npc;
    y.imm = v.imm;
    y.wren = v.wren;
    y.rden1 = v.rden1;
    y.rden2 = v.rden2;
    y.cwren = v.cwren;
    y.crden = v.crden;
    y.waddr = v.waddr;
    y.raddr1 = v.raddr1;
    y.raddr2 = v.raddr2;
    y.caddr = v.caddr;
    y.auipc = v.auipc;
    y.lui = v.lui;
    y.jal = v.jal;
    y.jalr = v.jalr;
    y.branch = v.branch;
    y.load = v.load;
    y.store = v.store;
    y.nop = v.nop;
    y.csregister = v.csregister;
    y.division = v.division;
    y.multiplication = v.multiplication;
    y.bitmanipulation = v.bitmanipulation;
    y.fence = v.fence;
    y.ecall = v.ecall;
    y.ebreak = v.ebreak;
    y.mret = v.mret;
    y.wfi = v.wfi;
    y.valid = v.valid;
    y.jump = v.jump;
    y.rdata1 = v.rdata1;
    y.rdata2 = v.rdata2;
    y.cdata = v.cdata;
    y.address = v.address;
    y.byteenable = v.byteenable;
    y.alu_op = v.alu_op;
    y.bcu_op = v.bcu_op;
    y.lsu_op = v.lsu_op;
    y.csr_op = v.csr_op;
    y.div_op = v.div_op;
    y.mul_op = v.mul_op;
    y.bit_op = v.bit_op;
    y.exception = v.exception;
    y.ecause = v.ecause;
    y.etval = v.etval;
    y.stall = v.stall;

    q.pc = r.pc;
    q.npc = r.npc;
    q.imm = r.imm;
    q.wren = r.wren;
    q.rden1 = r.rden1;
    q.rden2 = r.rden2;
    q.cwren = r.cwren;
    q.crden = r.crden;
    q.waddr = r.waddr;
    q.raddr1 = r.raddr1;
    q.raddr2 = r.raddr2;
    q.caddr = r.caddr;
    q.auipc = r.auipc;
    q.lui = r.lui;
    q.jal = r.jal;
    q.jalr = r.jalr;
    q.branch = r.branch;
    q.load = r.load;
    q.store = r.store;
    q.nop = r.nop;
    q.csregister = r.csregister;
    q.division = r.division;
    q.multiplication = r.multiplication;
    q.bitmanipulation = r.bitmanipulation;
    q.fence = r.fence;
    q.ecall = r.ecall;
    q.ebreak = r.ebreak;
    q.mret = r.mret;
    q.wfi = r.wfi;
    q.valid = r.valid;
    q.jump = r.jump;
    q.rdata1 = r.rdata1;
    q.rdata2 = r.rdata2;
    q.cdata = r.cdata;
    q.address = r.address;
    q.byteenable = r.byteenable;
    q.alu_op = r.alu_op;
    q.bcu_op = r.bcu_op;
    q.lsu_op = r.lsu_op;
    q.csr_op = r.csr_op;
    q.div_op = r.div_op;
    q.mul_op = r.mul_op;
    q.bit_op = r.bit_op;
    q.exception = r.exception;
    q.ecause = r.ecause;
    q.etval = r.etval;
    q.stall = r.stall;

  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      r <= init_decode_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
