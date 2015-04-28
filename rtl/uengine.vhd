library IEEE;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;


entity UENGINE is
	port (
		LED1 : out std_logic;
		LED2 : out std_logic;
		--LED3 : out std_logic;
		--LED4 : out std_logic;
		clkin : in std_logic
	);
end;

architecture syn of UENGINE is
	signal count : unsigned(23 downto 0) := (others => '0');
	
	signal PC : unsigned(15 downto 0);

	subtype register_t is unsigned(15 downto 0);
	type registers_t is array (0 to 15) of register_t;
	signal R : registers_t;

	signal flag_Z : std_logic; -- zero
	signal flag_C : std_logic; -- carry

	signal uPC : integer range 0 to 65535;
	--signal ADDR: unsigned(15 downto 0) := (others => '0');
	signal ADDR: integer range 0 to 65535;
	signal MBR : unsigned(15 downto 0);
	signal INSTR : unsigned(7 downto 0);

	
	signal X : unsigned(15 downto 0) := (others => '0');
	signal Y : unsigned(15 downto 0) :=  "0000000000001010"; -- (others => '0');

	signal Z : unsigned(15 downto 0) := (others => '0');

	subtype alu_op_t is std_logic_vector(2 downto 0);
	
	constant AluNone : alu_op_t := "000";
	constant AluCopy : alu_op_t := "001";
	constant AluAdd : alu_op_t := "010";

	constant Zero : unsigned(15 downto 0) := "0000000000000000";
	constant One : unsigned(15 downto 0) := "0000000000000001";
	constant MaxInt : unsigned(15 downto 0) := "1111111111111111";

	constant IncPc : unsigned(1 downto 0) := "00";
	constant JmpRel : unsigned(1 downto 0) := "01";
	constant JmpAbs : unsigned(1 downto 0) := "10";

	subtype cond_t is std_logic_vector(2 downto 0);
	constant CondNever : cond_t := "000";
	constant CondZero : cond_t := "001";
	constant CondCarry : cond_t := "010";
	constant CondNotZero : cond_t := "101";
	constant CondNotCarry : cond_t := "110";
	constant CondAlways : cond_t := "111";

	subtype reg_op_t is integer range 0 to 15;

	type ucode_t is
		record
			pc : unsigned(1 downto 0);
			cond : cond_t;
			alu_op : alu_op_t;
			src_0 : reg_op_t;
			src_1 : reg_op_t;
			dst : reg_op_t;
			use_immediate : std_logic;
			immediate : unsigned(15 downto 0);
		end record;

	type ucode_array_t is array (0 to 15) of ucode_t;
	
	constant ucode : ucode_array_t := (
		(IncPc, CondAlways, AluCopy, 0, 0, 0, '1', Zero),  -- R0 <- 0
		(IncPc, CondAlways, AluCopy, 0, 0, 1, '1', One),   -- R1 <- 1
		(IncPc, CondAlways, AluCopy, 0, 0, 2, '1', One),   -- R2 <- 1
		(IncPc, CondAlways, AluAdd,  1, 2, 0, '0', Zero),  -- R0 <- R1 + R2
		(IncPc, CondAlways, AluCopy, 0, 0, 0, '1', One),   -- R0 <- 1
		(JmpAbs, CondNotZero, AluNone, 0, 0, 0, '0', One), -- JMP 1
		(JmpAbs, CondZero, AluNone, 0, 0, 0, '0', Zero), -- JMP 0
		others => (JmpAbs, CondAlways, AluNone, 0, 0, 0, '0', Zero)
		);

begin
	process(clkin)
		variable uop : ucode_t;
		variable res : unsigned(16 downto 0);
	begin
		if rising_edge(clkin) then
			if count = 0 then
				uop := ucode(uPC);

				if uop.alu_op = AluCopy then
					if uop.use_immediate = '1' then
						R(uop.dst) <= uop.immediate;
					end if;
				elsif uop.alu_op = AluAdd then
					res := ("0" & R(uop.src_0)) + ("0" & R(uop.src_1));
					R(uop.dst) <= res(15 downto 0);
					flag_C <= res(16);
					if res(15 downto 0) = Zero then
						flag_Z <= '1';
					else
						flag_Z <= '0';
					end if;
				end if;

				if uop.pc = IncPc then
					uPC <= uPC + 1;
				elsif uop.pc = JmpAbs then
					if uop.cond = CondAlways then
						uPC <= to_integer(uop.immediate);
					elsif uop.cond = CondZero and flag_Z = '1' then
						uPC <= to_integer(uop.immediate);
					elsif uop.cond = CondCarry and flag_C = '1' then
						uPC <= to_integer(uop.immediate);
					elsif uop.cond = CondNotZero and flag_Z = '0' then
						uPC <= to_integer(uop.immediate);
					elsif uop.cond = CondNotCarry and flag_C = '0' then
						uPC <= to_integer(uop.immediate);
					else
						uPC <= uPC + 1;
					end if;
				end if;

				
				LED1 <= R(0)(0);
				LED2 <= R(0)(1);

			end if;

			count <= count + 1;

		end if;
	end process;
end;
