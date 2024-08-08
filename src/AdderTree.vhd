-----------------------------------------------------------------------------
-- A module to calculate the sum of n number of inputs in adder tree format
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity AdderTree is
    generic (
		INPUT_WIDTH : integer := 2; 
		OUTPUT_WIDTH: integer := 8; -- Cannot be less then Input_width + log2(INPUT_NUMBER)!!
		INPUT_NUMBER: integer := 45
    );
    port (
        clk   : in  std_logic;
        din   : in  std_logic_vector(INPUT_WIDTH*INPUT_NUMBER-1 downto 0);
        dout  : out std_logic_vector(OUTPUT_WIDTH-1  downto 0)
    );
end entity;


architecture behavioral of AdderTree is


-- Calculate the 2-base logorithm of given number 
function clogb2( depth : natural) return integer is
    variable temp    : integer := depth;
    variable ret_val : integer := 0;
    begin
        while temp > 1 loop
            ret_val := ret_val + 1;
            temp    := temp / 2;
        end loop;
        return ret_val;
end function;

constant num_left_inputs : integer := INPUT_NUMBER - INPUT_NUMBER/2;
constant num_right_inputs : integer := INPUT_NUMBER/2;
constant left_tree_depth : integer := clogb2(num_left_inputs);
constant right_tree_depth : integer := clogb2(num_right_inputs);
constant latency_difference : integer := left_tree_depth - right_tree_depth;


signal left_sum : std_logic_vector(INPUT_WIDTH + clogb2(num_left_inputs) -1 downto 0);
signal right_sum_unaligned : std_logic_vector((INPUT_WIDTH + clogb2(num_right_inputs)) -1 downto 0);
signal right_sum : std_logic_vector((INPUT_WIDTH + clogb2(num_right_inputs)) -1 downto 0);

type delay_r_type is array(0 to latency_difference) of std_logic_vector((INPUT_WIDTH + clogb2(num_right_inputs))-1 downto 0);
signal delay_r : delay_r_type;


begin

-- Base Case for the recursion
base_1 : if INPUT_NUMBER = 1 generate
    dout <= din;
end generate;


recursive_module : if INPUT_NUMBER > 1 generate
    left_tree: entity work.AdderTree
        generic map (
            INPUT_NUMBER => num_left_inputs,
            INPUT_WIDTH => INPUT_WIDTH,
            OUTPUT_WIDTH => INPUT_WIDTH + clogb2(num_left_inputs)
        )
        port map (
            clk   => clk,
            din   => din(num_left_inputs*INPUT_WIDTH -1 downto 0), 
            dout  => left_sum           
        );
    
    right_tree: entity work.AdderTree
        generic map (
            INPUT_NUMBER => num_right_inputs,
            INPUT_WIDTH => INPUT_WIDTH,
            OUTPUT_WIDTH => INPUT_WIDTH + clogb2(num_right_inputs)
        )
        port map (
            clk   => clk,
            din   => din(INPUT_NUMBER*INPUT_WIDTH-1 downto num_left_inputs*INPUT_WIDTH),
            dout  => right_sum_unaligned
        );


    latency : if latency_difference > 0 generate
        process (clk)
        begin
        if rising_edge(clk) then
            delay_r(0) <= right_sum_unaligned;

            for i in 0 to latency_difference-1 loop
                delay_r(i+1) <= delay_r(i);

            end loop;
            right_sum <= delay_r(latency_difference-1);
        end if;
        end process;
    
    end generate latency;

    no_latency : if latency_difference = 0 generate
        right_sum <= right_sum_unaligned;

    end generate no_latency;



dout <= std_logic_vector(to_signed(to_integer(signed(left_sum)) + to_integer(signed(right_sum)), OUTPUT_WIDTH));





end generate recursive_module;
    

end architecture;


------------------------------------------------------------------
---------------------------- SELIMI ------------------------------
------------------------------------------------------------------
