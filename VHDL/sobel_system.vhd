library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.sobel_pkg.ALL;

entity sobel_system is
    Generic (
        DATA_WIDTH  : integer := 8;
        LINE_LENGTH : integer := 100
    );
    Port (
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;

        -- Control Inputs
        start           : in  STD_LOGIC;
        pixel_valid_in  : in  STD_LOGIC;

        -- Data Input
        pixel_in        : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

        -- System Outputs
        magnitude_out   : out STD_LOGIC_VECTOR(10 downto 0);
        pixel_valid_out : out STD_LOGIC;
        frame_done      : out STD_LOGIC
    );
end sobel_system;


architecture Structural of sobel_system is

    -- ==========================================
    -- CONTROL SIGNALS
    -- ==========================================

    signal sig_we_lb   : STD_LOGIC;
    signal sig_we_win  : STD_LOGIC;
    signal sig_we_math : STD_LOGIC;


    -- ==========================================
    -- LINE BUFFER SIGNALS
    -- ==========================================

    signal sig_lb0_out : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_lb1_out : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);


    -- ==========================================
    -- 3x3 WINDOW SIGNALS
    -- ==========================================

    signal sig_p00 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p01 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p02 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

    signal sig_p10 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p11 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p12 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

    signal sig_p20 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p21 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sig_p22 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);


    -- ==========================================
    -- SOBEL GRADIENT SIGNALS
    -- ==========================================

    signal sig_gx : STD_LOGIC_VECTOR(10 downto 0);
    signal sig_gy : STD_LOGIC_VECTOR(10 downto 0);


begin


    -- ==========================================
    -- 1. CONTROL UNIT (FSM)
    -- ==========================================

    u_fsm : sobel_fsm
        port map (
            clk             => clk,
            rst             => rst,
            start           => start,
            pixel_valid_in  => pixel_valid_in,

            we_lb           => sig_we_lb,
            we_win          => sig_we_win,
            we_math         => sig_we_math,

            pixel_valid_out => pixel_valid_out,
            frame_done      => frame_done
        );


    -- ==========================================
    -- 2. MEMORY PIPELINE
    -- ==========================================
    --
    -- First line buffer:
    -- pixel_in -> linebuffer 0
    --
    -- Second line buffer:
    -- linebuffer 0 -> linebuffer 1
    --
    -- Therefore:
    -- sig_lb1_out = pixel from two rows earlier
    -- sig_lb0_out = pixel from one row earlier
    -- pixel_in    = current row pixel
    --
    -- ==========================================

    u_linebuffer0 : linebuffer
        generic map (
            DATA_WIDTH  => DATA_WIDTH,
            LINE_LENGTH => LINE_LENGTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            we       => sig_we_lb,

            data_in  => pixel_in,
            data_out => sig_lb0_out
        );


    u_linebuffer1 : linebuffer
        generic map (
            DATA_WIDTH  => DATA_WIDTH,
            LINE_LENGTH => LINE_LENGTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            we       => sig_we_lb,

            data_in  => sig_lb0_out,
            data_out => sig_lb1_out
        );


    -- ==========================================
    -- 3. 3x3 SLIDING WINDOW EXTRACTOR
    -- ==========================================
    --
    -- Top row    = linebuffer 1 output
    -- Middle row = linebuffer 0 output
    -- Bottom row = current input pixel
    --
    -- ==========================================

    u_window : window_extractor_3x3
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            rst => rst,
            we  => sig_we_win,

            row0_in => sig_lb1_out,
            row1_in => sig_lb0_out,
            row2_in => pixel_in,

            p00 => sig_p00,
            p01 => sig_p01,
            p02 => sig_p02,

            p10 => sig_p10,
            p11 => sig_p11,
            p12 => sig_p12,

            p20 => sig_p20,
            p21 => sig_p21,
            p22 => sig_p22
        );


    -- ==========================================
    -- 4. SOBEL GRADIENT CALCULATOR
    -- ==========================================

    u_gradients : sobel_gradients
        port map (
            clk => clk,
            rst => rst,
            we  => sig_we_math,

            p00 => sig_p00,
            p01 => sig_p01,
            p02 => sig_p02,

            p10 => sig_p10,
            p11 => sig_p11,
            p12 => sig_p12,

            p20 => sig_p20,
            p21 => sig_p21,
            p22 => sig_p22,

            gx_out => sig_gx,
            gy_out => sig_gy
        );


    -- ==========================================
    -- 5. MAGNITUDE CALCULATOR
    -- ==========================================
    --
    -- Hardware magnitude:
    --
    --       |Gx| + |Gy|
    --
    -- This is the Manhattan approximation
    -- specified by the project.
    --
    -- ==========================================

    u_magnitude : magnitude_calc
        port map (
            clk => clk,
            rst => rst,
            we  => sig_we_math,

            gx_in => sig_gx,
            gy_in => sig_gy,

            mag_out => magnitude_out
        );


end Structural;