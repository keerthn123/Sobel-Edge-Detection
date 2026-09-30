library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_fsm is
    generic (
        IMAGE_WIDTH  : integer := 100;
        IMAGE_HEIGHT : integer := 100
    );
    Port (
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;
        start           : in  STD_LOGIC;
        pixel_valid_in  : in  STD_LOGIC;
        
        -- Control Signals to the Pipeline
        we_lb           : out STD_LOGIC;
        we_win          : out STD_LOGIC;
        we_math         : out STD_LOGIC;
        
        -- Status Signals
        pixel_valid_out : out STD_LOGIC;
        frame_done      : out STD_LOGIC
    );
end sobel_fsm;

architecture rtl of sobel_fsm is

    type state_type is (
        IDLE,
        FILL_LB0,
        FILL_LB1,
        PROCESS_ROW,
        FINISHED
    );

    signal current_state : state_type;

    signal col_count : integer range 0 to IMAGE_WIDTH - 1 := 0;
    signal row_count : integer range 0 to IMAGE_HEIGHT - 1 := 0;

    type control_bus_t is record
        valid : std_logic;
        eof   : std_logic;
    end record;

    constant PIPELINE_STAGES : integer := 3;

    type control_pipe_t is array (0 to PIPELINE_STAGES-1)
        of control_bus_t;

    signal ctrl_pipe : control_pipe_t :=
        (others => ('0', '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then

                current_state <= IDLE;

                col_count <= 0;
                row_count <= 0;

                we_lb <= '0';
                we_win <= '0';
                we_math <= '0';

                pixel_valid_out <= '0';
                frame_done <= '0';

                ctrl_pipe <= (others => ('0', '0'));

            else

                -- Default write enables
                we_lb <= '0';
                we_win <= '0';
                we_math <= '0';

                -- Shift the control pipeline
                ctrl_pipe(2) <= ctrl_pipe(1);
                ctrl_pipe(1) <= ctrl_pipe(0);

                -- Clear new pipeline input
                ctrl_pipe(0).valid <= '0';
                ctrl_pipe(0).eof <= '0';

                -- Delayed output signals
                pixel_valid_out <= ctrl_pipe(2).valid;
                frame_done <= ctrl_pipe(2).eof;


                case current_state is


                    -- ==========================================
                    -- IDLE
                    -- ==========================================

                    when IDLE =>

                        col_count <= 0;
                        row_count <= 0;

                        if start = '1' then
                            current_state <= FILL_LB0;
                        end if;


                    -- ==========================================
                    -- FILL_LB0
                    -- First image row
                    -- ==========================================

                    when FILL_LB0 =>

                        if pixel_valid_in = '1' then

                            we_lb <= '1';
                            we_win <= '1';

                            if col_count < IMAGE_WIDTH - 1 then

                                col_count <= col_count + 1;

                            else

                                col_count <= 0;
                                row_count <= 1;
                                current_state <= FILL_LB1;

                            end if;

                        end if;


                    -- ==========================================
                    -- FILL_LB1
                    -- Second image row
                    -- ==========================================

                    when FILL_LB1 =>

                        if pixel_valid_in = '1' then

                            we_lb <= '1';
                            we_win <= '1';

                            if col_count < IMAGE_WIDTH - 1 then

                                col_count <= col_count + 1;

                            else

                                col_count <= 0;
                                row_count <= 2;
                                current_state <= PROCESS_ROW;

                            end if;

                        end if;


                    -- ==========================================
                    -- PROCESS_ROW
                    -- Main Sobel processing state
                    -- ==========================================

                    when PROCESS_ROW =>

                        if pixel_valid_in = '1' then

                            we_lb <= '1';
                            we_win <= '1';
                            we_math <= '1';

                            -- The first two columns do not yet
                            -- contain a complete 3x3 window.
                            if col_count >= 2 then
                                ctrl_pipe(0).valid <= '1';
                            end if;


                            -- Last pixel of the complete image
                            if (col_count = IMAGE_WIDTH - 1) and
                               (row_count = IMAGE_HEIGHT - 1) then

                                ctrl_pipe(0).eof <= '1';
                                current_state <= FINISHED;


                            -- Last pixel of a normal row
                            elsif col_count = IMAGE_WIDTH - 1 then

                                col_count <= 0;
                                row_count <= row_count + 1;


                            -- Normal pixel
                            else

                                col_count <= col_count + 1;

                            end if;

                        end if;


                    -- ==========================================
                    -- FINISHED
                    -- ==========================================

                    when FINISHED =>

                        -- All write enables stay at '0'.

                        -- Wait until the external controller
                        -- releases start before accepting
                        -- another frame.
                        if start = '0' then

                            current_state <= IDLE;
                            col_count <= 0;
                            row_count <= 0;

                        end if;


                end case;

            end if;

        end if;

    end process;

end architecture rtl;