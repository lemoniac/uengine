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

	subtype reg_op_t is integer range 0 to 15;

	type ucode_t is
		record
			pc : unsigned(1 downto 0);
			alu_op : alu_op_t;
			src_0 : reg_op_t;
			src_1 : reg_op_t;
			dst : reg_op_t;
			use_immediate : std_logic;
			immediate : unsigned(15 downto 0);
		end record;

	type ucode_array_t is array (0 to 15) of ucode_t;
	
	constant ucode : ucode_array_t := (
		(IncPc, AluCopy, 0, 0, 0, '1', Zero),  -- R0 <- 0
		(IncPc, AluCopy, 0, 0, 1, '1', One),   -- R1 <- 1
		(IncPc, AluCopy, 0, 0, 2, '1', One),   -- R2 <- 1
		(IncPc, AluAdd,  1, 2, 0, '0', Zero),  -- R0 <- R1 + R2
		(IncPc, AluCopy, 0, 0, 0, '1', One),   -- R0 <- 1
		(JmpAbs, AluNone, 0, 0, 0, '0', Zero), -- JMP 0
		others => (JmpAbs, AluNone, 0, 0, 0, '0', Zero)
		);

begin
	process(clkin)
		variable uop : ucode_t;
	begin
		if rising_edge(clkin) then
			if count = 0 then
				uop := ucode(uPC);

				if uop.alu_op = AluCopy then
					if uop.use_immediate = '1' then
						R(uop.dst) <= uop.immediate;
					end if;
				elsif uop.alu_op = AluAdd then
					R(uop.dst) <= R(uop.src_0) + R(uop.src_1);
				end if;

				if uop.pc = IncPc then
					uPC <= uPC + 1;
				elsif uop.pc = JmpAbs then
					uPC <= to_integer(uop.immediate);
				end if;

				
				LED1 <= R(0)(0);
				LED2 <= R(0)(1);

			end if;

			count <= count + 1;

		end if;
	end process;
end;
