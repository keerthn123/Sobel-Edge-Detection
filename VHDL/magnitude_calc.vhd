library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity magnitude_calc is
    Port (
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        we      : in  STD_LOGIC;
        gx_in   : in  STD_LOGIC_VECTOR(10 downto 0);
        gy_in   : in  STD_LOGIC_VECTOR(10 downto 0);
        
        mag_out : out STD_LOGIC_VECTOR(10 downto 0)
    );
end magnitude_calc;

architecture Structural of magnitude_calc is

    component add_sub_n is
        Generic ( N : integer := 11 );
        Port (
            A    : in  STD_LOGIC_VECTOR(N-1 downto 0);
            B    : in  STD_LOGIC_VECTOR(N-1 downto 0);
            sub  : in  STD_LOGIC;
            Sum  : out STD_LOGIC_VECTOR(N-1 downto 0);
            Cout : out STD_LOGIC
        );
    end component;

    -- A constant zero vector
    constant ZERO_11 : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');

    -- Internal combinational signals
    signal abs_gx   : STD_LOGIC_VECTOR(10 downto 0);
    signal abs_gy   : STD_LOGIC_VECTOR(10 downto 0);
    signal mag_comb : STD_LOGIC_VECTOR(10 downto 0);

    -- Negative values of Gx and Gy
    signal neg_gx   : STD_LOGIC_VECTOR(10 downto 0);
    signal neg_gy   : STD_LOGIC_VECTOR(10 downto 0);

begin

    -- ==========================================
    -- 1. ABSOLUTE VALUE OF Gx
    -- ==========================================

    gx_negative : add_sub_n
        generic map (N => 11)
        port map (
            A    => ZERO_11,
            B    => gx_in,
            sub  => '1',
            Sum  => neg_gx,
            Cout => open
        );

    process(gx_in, neg_gx)
    begin
        if gx_in(10) = '1' then
            abs_gx <= neg_gx;
        else
            abs_gx <= gx_in;
        end if;
    end process;


    -- ==========================================
    -- 2. ABSOLUTE VALUE OF Gy
    -- ==========================================

    gy_negative : add_sub_n
        generic map (N => 11)
        port map (
            A    => ZERO_11,
            B    => gy_in,
            sub  => '1',
            Sum  => neg_gy,
            Cout => open
        );

    process(gy_in, neg_gy)
    begin
        if gy_in(10) = '1' then
            abs_gy <= neg_gy;
        else
            abs_gy <= gy_in;
        end if;
    end process;


    -- ==========================================
    -- 3. MAGNITUDE SUM
    -- ==========================================

    magnitude_add : add_sub_n
        generic map (N => 11)
        port map (
            A    => abs_gx,
            B    => abs_gy,
            sub  => '0',
            Sum  => mag_comb,
            Cout => open
        );


    -- ==========================================
    -- 4. SYNCHRONOUS OUTPUT PIPELINE REGISTER
    -- ==========================================

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                mag_out <= (others => '0');

            elsif we = '1' then
                mag_out <= mag_comb;
            end if;

        end if;
    end process;

end Structural;