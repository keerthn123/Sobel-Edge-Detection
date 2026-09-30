library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity window_extractor_3x3 is
    Generic (
        -- Generics use integer purely to define bus width at compile time
        DATA_WIDTH : integer := 8 
    );
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        we       : in  STD_LOGIC; -- Write enable / Data valid signal
        
        -- The 3 vertically aligned incoming pixels
        row0_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); -- Top row (from Line Buffer 1)
        row1_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); -- Middle row (from Line Buffer 0)
        row2_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); -- Bottom row (Live stream)
        
        -- The 3x3 output window 
        -- Naming convention: p<row><column> 
        -- (e.g., p00 is top-left, p11 is center, p22 is bottom-right)
        
        -- Row 0 Outputs (Top)
        p00 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p01 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p02 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        
        -- Row 1 Outputs (Middle)
        p10 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p11 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p12 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        
        -- Row 2 Outputs (Bottom)
        p20 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p21 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        p22 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
    );
end window_extractor_3x3;

architecture Behavioral of window_extractor_3x3 is

    signal reg00, reg01, reg02 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0) := (others => '0');
    signal reg10, reg11, reg12 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0) := (others => '0');
    signal reg20, reg21, reg22 : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset: Clear the entire 3x3 grid
                reg00 <= (others => '0'); reg01 <= (others => '0'); reg02 <= (others => '0');
                reg10 <= (others => '0'); reg11 <= (others => '0'); reg12 <= (others => '0');
                reg20 <= (others => '0'); reg21 <= (others => '0'); reg22 <= (others => '0');
                
            elsif we = '1' then
                -- Shift Row 0 (Top Row)
                -- Newest pixel enters at the right (02), oldest shifts out the left (00)
                reg00 <= reg01;
                reg01 <= reg02;
                reg02 <= row0_in;
                
                -- Shift Row 1 (Middle Row)
                reg10 <= reg11;
                reg11 <= reg12;
                reg12 <= row1_in;
                
                -- Shift Row 2 (Bottom Row)
                reg20 <= reg21;
                reg21 <= reg22;
                reg22 <= row2_in;
            end if;
        end if;
    end process;

    --Wire the internal register states directly to the output pins
    p00 <= reg00; p01 <= reg01; p02 <= reg02;
    p10 <= reg10; p11 <= reg11; p12 <= reg12;
    p20 <= reg20; p21 <= reg21; p22 <= reg22;

end Behavioral;