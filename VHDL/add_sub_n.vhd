---------------------------------------------
--Description: Adder and Subtractor
---------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_sub_n is
    Generic ( N : integer := 11 );
    Port (
        A    : in  STD_LOGIC_VECTOR(N-1 downto 0);
        B    : in  STD_LOGIC_VECTOR(N-1 downto 0);
        sub  : in  STD_LOGIC; -- '0' for Add, '1' for Subtract
        Sum  : out STD_LOGIC_VECTOR(N-1 downto 0);
        Cout : out STD_LOGIC
    );
end add_sub_n;

architecture behavioral of add_sub_n is

    -- Internal arrays for Propagate, Generate, and the Lookahead Carries
    signal P     : STD_LOGIC_VECTOR(N-1 downto 0);
    signal G     : STD_LOGIC_VECTOR(N-1 downto 0);
    signal B_eff : STD_LOGIC_VECTOR(N-1 downto 0);
    signal C     : STD_LOGIC_VECTOR(N downto 0);

begin

    -- ==========================================
    -- 1. Generate (G) and Propagate (P) Setup
    -- ==========================================
    gen_PG: for i in 0 to N-1 generate
    begin
        -- If 'sub' is 1, B is inverted for Two's Complement
        B_eff(i) <= B(i) xor sub; 
        
        -- Propagate (P) = A XOR B
        P(i) <= A(i) xor B_eff(i);
        
        -- Generate (G) = A AND B
        G(i) <= A(i) and B_eff(i);
    end generate;

    -- ==========================================
    -- 2. Parallel Carry Lookahead Logic
    -- ==========================================
    
    process(P, G, sub)
        variable temp_C    : STD_LOGIC;
        variable temp_term : STD_LOGIC;
    begin
        -- Base carry-in completes the Two's Complement logic for subtraction
        C(0) <= sub; 
        
        for i in 1 to N loop
            -- Start with the Generate term from the bit immediately below
            temp_C := G(i-1);
            
            -- Build the cascaded Propagate AND Generate terms
            if i > 1 then
                for j in i-2 downto 0 loop
                    temp_term := G(j);
                    for k in j+1 to i-1 loop
                        temp_term := temp_term and P(k);
                    end loop;
                    temp_C := temp_C or temp_term;
                end loop;
            end if;
            
            -- Build the final term propagating the initial Carry In ('sub')
            temp_term := sub;
            for k in 0 to i-1 loop
                temp_term := temp_term and P(k);
            end loop;
            
            -- Output the final unrolled boolean logic for this carry bit
            C(i) <= temp_C or temp_term;
        end loop;
    end process;

    -- ==========================================
    -- 3. Final Sum Calculation
    -- ==========================================
    gen_sum: for i in 0 to N-1 generate
    begin
        -- Sum = P XOR C (calculated in parallel instantly)
        Sum(i) <= P(i) xor C(i);
    end generate;
    
    Cout <= C(N);

end behavioral;