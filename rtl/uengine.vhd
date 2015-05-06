library IEEE;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library work;
	use work.common.all;


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
	signal R : registers_t;

	signal flag_Z : std_logic; -- zero
	signal flag_C : std_logic; -- carry
	signal flag_N : std_logic; -- negative
	signal flag_V : std_logic; -- overflooded

	signal uPC : integer range 0 to 65535;
	--signal ADDR: unsigned(15 downto 0) := (others => '0');
	signal ADDR: integer range 0 to 65535;
	signal MBR : unsigned(15 downto 0);
	signal INSTR : unsigned(7 downto 0);

	
	signal X : unsigned(15 downto 0) := (others => '0');
	signal Y : unsigned(15 downto 0) :=  "0000000000001010"; -- (others => '0');

	signal Z : unsigned(15 downto 0) := (others => '0');

	constant Zero : unsigned(15 downto 0) := "0000000000000000";
	constant One : unsigned(15 downto 0) := "0000000000000001";
	constant MaxInt : unsigned(15 downto 0) := "1111111111111111";

	constant ucode : ucode_array_t := (
		(IncPc,  CondAlways,  AluMove, '1', 0, '0', 0, '0', 0, '0', '1', One),    -- R0 <- 1
		(IncPc,  CondAlways,  AluLsh,  '1', 0, '0', 0, '0', 0, '0', '0', Zero),   -- R0 <- R0 << 1
		(IncPc,  CondAlways,  AluRsh,  '1', 0, '0', 0, '0', 0, '0', '0', Zero),   -- R0 <- R0 >> 1
		(JmpAbs, CondAlways,  AluNone, '1', 0, '0', 0, '0', 0, '0', '0', One),    -- JMP 1
		others =>
		(JmpAbs, CondAlways,  AluNone, '1', 0, '0', 0, '0', 0, '0', '0', Zero)
		);

begin
	process(clkin)
		variable uop : ucode_t;
		variable res17 : unsigned(16 downto 0);
		variable res : unsigned(15 downto 0);
		variable B : unsigned(15 downto 0);		
	begin
		if rising_edge(clkin) then
			if count = 0 then
				uop := ucode(uPC);

				if uop.alu_op /= AluNone then
					if uop.use_immediate = '1' then
						B := uop.immediate;
					else
						B := R(uop.src_1);
					end if;

					if uop.alu_op = AluMove then
						res := uop.immediate;
					elsif uop.alu_op = AluAdd then
						res17 := ("0" & R(uop.src_0)) + ("0" & B);
						res := res17(15 downto 0);
						flag_C <= res17(16);
					elsif uop.alu_op = AluLsh then
						res := R(uop.src_0)(14 downto 0) & "0";
						flag_C <= R(uop.src_0)(15);
					elsif uop.alu_op = AluRsh then
						res := "0" & R(uop.src_0)(15 downto 1);
						flag_C <= R(uop.src_0)(0);
					elsif uop.alu_op = AluAnd then
						res := R(uop.src_0) and B;
					elsif uop.alu_op = AluOr then
						res := R(uop.src_0) or B;
					elsif uop.alu_op = AluXor then
						res := R(uop.src_0) xor B;
					elsif uop.alu_op = AluNot then
						res := not B;
					end if;

					R(uop.dst) <= res;

					if res = Zero then
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
