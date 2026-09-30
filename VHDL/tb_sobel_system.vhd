library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;
use work.sobel_pkg.ALL;

entity tb_sobel_system is
end tb_sobel_system;


architecture Behavioral of tb_sobel_system is

    -- ==========================================
    -- COMPONENT DECLARATION (DUT)
    -- ==========================================

    component sobel_system is
        Generic (
            DATA_WIDTH  : integer := 8;
            LINE_LENGTH : integer := 100
        );
        Port (
            clk             : in  STD_LOGIC;
            rst             : in  STD_LOGIC;
            start           : in  STD_LOGIC;
            pixel_valid_in  : in  STD_LOGIC;
            pixel_in        : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            magnitude_out   : out STD_LOGIC_VECTOR(10 downto 0);
            pixel_valid_out : out STD_LOGIC;
            frame_done      : out STD_LOGIC
        );
    end component;


    -- ==========================================
    -- TESTBENCH SIGNALS
    -- ==========================================

    signal clk             : STD_LOGIC := '0';
    signal rst             : STD_LOGIC := '0';
    signal start           : STD_LOGIC := '0';
    signal pixel_valid_in  : STD_LOGIC := '0';

    signal pixel_in        : STD_LOGIC_VECTOR(7 downto 0)
                           := (others => '0');

    signal magnitude_out   : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_valid_out : STD_LOGIC;
    signal frame_done      : STD_LOGIC;


    -- Clock period = 10 ns = 100 MHz
    constant CLK_PERIOD : time := 10 ns;


begin


    -- ==========================================
    -- INSTANTIATE THE DEVICE UNDER TEST
    -- ==========================================

    DUT : sobel_system
        generic map (
            DATA_WIDTH  => 8,
            LINE_LENGTH => 100
        )
        port map (
            clk             => clk,
            rst             => rst,
            start           => start,
            pixel_valid_in  => pixel_valid_in,
            pixel_in        => pixel_in,
            magnitude_out   => magnitude_out,
            pixel_valid_out => pixel_valid_out,
            frame_done      => frame_done
        );


    -- ==========================================
    -- CLOCK GENERATION
    -- ==========================================

    clk_process : process
    begin

        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;

    end process;


    -- ==========================================
    -- INPUT PROCESS
    -- Read pixels from imagesrc.txt
    -- ==========================================

    read_process : process

        file file_IN : text open read_mode
            is "C:/SOBEL_PROJECT/imagesrc.txt";

        variable v_ILINE   : line;
        variable v_BIT_VEC : bit_vector(7 downto 0);

    begin

        -- ======================================
        -- 1. RESET
        -- ======================================

        rst <= '1';
        pixel_valid_in <= '0';

        wait for CLK_PERIOD * 5;

        rst <= '0';

        wait for CLK_PERIOD * 5;


        -- ======================================
        -- 2. START
        -- ======================================

        start <= '1';

        wait for CLK_PERIOD;

        start <= '0';


        -- ======================================
        -- 3. SEND ALL IMAGE PIXELS
        -- ======================================

        while not endfile(file_IN) loop

            -- Read one line
            readline(file_IN, v_ILINE);

            -- Read 8-bit binary value
            read(v_ILINE, v_BIT_VEC);

            -- Convert to std_logic_vector
            pixel_in <= to_stdlogicvector(v_BIT_VEC);

            -- Pixel is valid
            pixel_valid_in <= '1';

            -- One pixel per clock
            wait for CLK_PERIOD;

        end loop;


        -- ======================================
        -- 4. END OF INPUT
        -- ======================================

        pixel_valid_in <= '0';

        wait;

    end process;


    -- ==========================================
    -- OUTPUT MONITOR
    -- Write valid Sobel results to file
    -- ==========================================

    write_process : process

        file file_OUT : text open write_mode
            is "C:/SOBEL_PROJECT/SobelEdgeVHDL.txt";

        variable v_OLINE : line;

    begin

        -- Keep checking every clock cycle
        loop

            wait until rising_edge(clk);


            -- ==================================
            -- Write valid output
            -- ==================================

            if pixel_valid_out = '1' then

                write(
                    v_OLINE,
                    to_integer(unsigned(magnitude_out))
                );

                writeline(file_OUT, v_OLINE);

            end if;


            -- ==================================
            -- Frame finished
            -- ==================================

            if frame_done = '1' then

                report "FRAME COMPLETE: Simulation Finished Successfully!"
                    severity note;

                stop(0);

            end if;

        end loop;

    end process;


end Behavioral;