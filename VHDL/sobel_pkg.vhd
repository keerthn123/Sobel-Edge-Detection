library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ==========================================
-- COMPLETE SOBEL FILTER COMPONENT PACKAGE
-- ==========================================
package sobel_pkg is

    -- 1. The Pure Logic Shift Register Line Buffer
    component linebuffer is
        Generic (
            DATA_WIDTH  : integer := 8;    
            LINE_LENGTH : integer := 100   -- Configured for your 100x100 image
        );
        Port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            we       : in  STD_LOGIC;
            data_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
            data_out : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
        );
    end component;

    -- 2. The 3x3 Sliding Window Extractor
    component window_extractor_3x3 is
        Generic (
            DATA_WIDTH : integer := 8 
        );
        Port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            we       : in  STD_LOGIC; 
            
            -- Row Inputs
            row0_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); 
            row1_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); 
            row2_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0); 
            
            -- Window Outputs
            p00, p01, p02 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
            p10, p11, p12 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
            p20, p21, p22 : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0)
        );
    end component;

    -- 3. The Generic N-Bit Carry Lookahead Adder/Subtractor
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

    -- 4. The Horizontal and Vertical Gradient Calculator
    component sobel_gradients is
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
    end component;

    -- 5. The Manhattan Distance Magnitude Calculator
    component magnitude_calc is
        Port (
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            we      : in  STD_LOGIC;
            
            -- Inputs from Gradients block
            gx_in   : in  STD_LOGIC_VECTOR(10 downto 0);
            gy_in   : in  STD_LOGIC_VECTOR(10 downto 0);
            
            -- Magnitude Output
            mag_out : out STD_LOGIC_VECTOR(10 downto 0)
        );
    end component;

    -- 6. The System Controller (Finite State Machine)
    component sobel_fsm is
        Port (
            clk             : in  STD_LOGIC;
            rst             : in  STD_LOGIC;
            start           : in  STD_LOGIC;
            pixel_valid_in  : in  STD_LOGIC;
            
            -- Pipeline Control Enable Signals
            we_lb           : out STD_LOGIC;
            we_win          : out STD_LOGIC;
            we_math         : out STD_LOGIC;
            
            -- Status Output Signals
            pixel_valid_out : out STD_LOGIC;
            frame_done      : out STD_LOGIC
        );
    end component;

end package sobel_pkg;