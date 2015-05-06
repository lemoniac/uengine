library IEEE;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

package common is

	subtype register_t is unsigned(15 downto 0);
	type registers_t is array (0 to 15) of register_t;

	subtype alu_op_t is std_logic_vector(3 downto 0);
	constant AluNone : alu_op_t := "0000";
	constant AluMove : alu_op_t := "0001";
	constant AluAdd  : alu_op_t := "0010";
	constant AluSub  : alu_op_t := "0011";
	constant AluLsh  : alu_op_t := "0100";
	constant AluRsh  : alu_op_t := "0101";
	constant AluAnd  : alu_op_t := "0110";
	constant AluOr   : alu_op_t := "0111";
	constant AluXor  : alu_op_t := "1000";
	constant AluNot  : alu_op_t := "1001";


	subtype cond_t is std_logic_vector(2 downto 0);
	constant CondNever    : cond_t := "000";
	constant CondZero     : cond_t := "001";
	constant CondCarry    : cond_t := "010";
	constant CondNotZero  : cond_t := "101";
	constant CondNotCarry : cond_t := "110";
	constant CondAlways   : cond_t := "111";

	subtype reg_op_t is integer range 0 to 15;

	constant IncPc  : unsigned(1 downto 0) := "00";
	constant JmpRel : unsigned(1 downto 0) := "01";
	constant JmpAbs : unsigned(1 downto 0) := "10";

	type ucode_t is
		record
			pc : unsigned(1 downto 0);
			cond : cond_t;
			alu_op : alu_op_t;
			alu_16: std_logic; -- '0' 8bit, '1' 16bit
			src_0 : reg_op_t;
			src_0_hi: std_logic; -- '1' use high bits of register when 8bits
			src_1 : reg_op_t;
			src_1_hi: std_logic;
			dst : reg_op_t;
			dst_hi: std_logic;
			use_immediate : std_logic;
			immediate : unsigned(15 downto 0);
		end record;

	type ucode_array_t is array (0 to 15) of ucode_t;

end common;