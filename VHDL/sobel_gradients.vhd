library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sobel_gradients is
    Port (
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        we  : in  STD_LOGIC;
        
        -- 3x3 Window Inputs (8-bit)
        p00, p01, p02 : in STD_LOGIC_VECTOR(7 downto 0);
        p10, p11, p12 : in STD_LOGIC_VECTOR(7 downto 0);
        p20, p21, p22 : in STD_LOGIC_VECTOR(7 downto 0);
        
        -- Gradients Output (11-bit signed Two's Complement)
        gx_out : out STD_LOGIC_VECTOR(10 downto 0);
        gy_out : out STD_LOGIC_VECTOR(10 downto 0)
    );
end sobel_gradients;

architecture Structural of sobel_gradients is

    component add_sub_n is
        Generic ( N : integer := 11 );
        Port (
            A, B : in  STD_LOGIC_VECTOR(N-1 downto 0);
            sub  : in  STD_LOGIC;
            Sum  : out STD_LOGIC_VECTOR(N-1 downto 0);
            Cout : out STD_LOGIC
        );
    end component;

    -- Padded signals to 11 bits. 
    signal pad_p00, pad_p02 : STD_LOGIC_VECTOR(10 downto 0);
    signal pad_p20, pad_p22 : STD_LOGIC_VECTOR(10 downto 0);
    signal pad_p10_x2, pad_p12_x2 : STD_LOGIC_VECTOR(10 downto 0);
    signal pad_p01_x2, pad_p21_x2 : STD_LOGIC_VECTOR(10 downto 0);
    
    -- Intermediate Sums
    signal sum_gx_L1, sum_gx_L_total : STD_LOGIC_VECTOR(10 downto 0);
    signal sum_gx_R1, sum_gx_R_total : STD_LOGIC_VECTOR(10 downto 0);
    signal sum_gy_T1, sum_gy_T_total : STD_LOGIC_VECTOR(10 downto 0);
    signal sum_gy_B1, sum_gy_B_total : STD_LOGIC_VECTOR(10 downto 0);
    
    -- Final Combinational Gradients
    signal gx_comb, gy_comb : STD_LOGIC_VECTOR(10 downto 0);

begin

    -- Zero-extend the 8-bit pixels to 11 bits
    pad_p00 <= "000" & p00;
    pad_p02 <= "000" & p02;
    pad_p20 <= "000" & p20;
    pad_p22 <= "000" & p22;

    -- Multiply middle pixels by 2
    pad_p10_x2 <= "00" & p10 & '0';
    pad_p12_x2 <= "00" & p12 & '0';
    pad_p01_x2 <= "00" & p01 & '0';
    pad_p21_x2 <= "00" & p21 & '0';


    -- =========================================================
    -- Gx LEFT SIDE: p00 + 2*p10 + p20
    -- =========================================================

    gx_left_1 : add_sub_n
        generic map (N => 11)
        port map (
            A    => pad_p00,
            B    => pad_p10_x2,
            sub  => '0',
            Sum  => sum_gx_L1,
            Cout => open
        );

    gx_left_2 : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gx_L1,
            B    => pad_p20,
            sub  => '0',
            Sum  => sum_gx_L_total,
            Cout => open
        );


    -- =========================================================
    -- Gx RIGHT SIDE: p02 + 2*p12 + p22
    -- =========================================================

    gx_right_1 : add_sub_n
        generic map (N => 11)
        port map (
            A    => pad_p02,
            B    => pad_p12_x2,
            sub  => '0',
            Sum  => sum_gx_R1,
            Cout => open
        );

    gx_right_2 : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gx_R1,
            B    => pad_p22,
            sub  => '0',
            Sum  => sum_gx_R_total,
            Cout => open
        );


    -- =========================================================
    -- Gx = RIGHT - LEFT
    -- =========================================================

    gx_final : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gx_R_total,
            B    => sum_gx_L_total,
            sub  => '1',
            Sum  => gx_comb,
            Cout => open
        );


    -- =========================================================
    -- Gy TOP SIDE: p00 + 2*p01 + p02
    -- =========================================================

    gy_top_1 : add_sub_n
        generic map (N => 11)
        port map (
            A    => pad_p00,
            B    => pad_p01_x2,
            sub  => '0',
            Sum  => sum_gy_T1,
            Cout => open
        );

    gy_top_2 : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gy_T1,
            B    => pad_p02,
            sub  => '0',
            Sum  => sum_gy_T_total,
            Cout => open
        );


    -- =========================================================
    -- Gy BOTTOM SIDE: p20 + 2*p21 + p22
    -- =========================================================

    gy_bottom_1 : add_sub_n
        generic map (N => 11)
        port map (
            A    => pad_p20,
            B    => pad_p21_x2,
            sub  => '0',
            Sum  => sum_gy_B1,
            Cout => open
        );

    gy_bottom_2 : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gy_B1,
            B    => pad_p22,
            sub  => '0',
            Sum  => sum_gy_B_total,
            Cout => open
        );


    -- =========================================================
    -- Gy = BOTTOM - TOP
    -- =========================================================

    gy_final : add_sub_n
        generic map (N => 11)
        port map (
            A    => sum_gy_B_total,
            B    => sum_gy_T_total,
            sub  => '1',
            Sum  => gy_comb,
            Cout => open
        );


    -- =========================================================
    -- Registered outputs
    -- =========================================================

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                gx_out <= (others => '0');
                gy_out <= (others => '0');

            elsif we = '1' then
                gx_out <= gx_comb;
                gy_out <= gy_comb;
            end if;
        end if;
    end process;

end Structural;