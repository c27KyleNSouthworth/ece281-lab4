library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_clk, w_clk_tdm : std_logic;
    signal w_floor1, w_floor2 : std_logic_vector(3 downto 0);
  
    --signal w_seg     : std_logic_vector(6 downto 0); -- Output from decoder
    signal w_mux_o : std_logic_vector(3 downto 0); -- Output from TDM4
    signal w_sel     : std_logic_vector(3 downto 0); -- TDM4 selector (anodes)
    signal clk_reset, fsm_reset : std_logic;

   

	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );   
    end component clock_divider;
  
begin
	-- PORT MAPS ----------------------------------------
	
	
	U_decoder: sevenseg_decoder
	   port map(
	       i_Hex => w_mux_o, --w_mux_o for double  w_floor1
	       o_seg_n => seg
	       );

	   
	elevator_control_inst1 : elevator_controller_fsm
	   port map(
            i_clk => w_clk,
            i_reset => fsm_reset,
            is_stopped => sw(0),
            go_up_down => sw(1),
            o_floor => w_floor1
        );
        
    elevator_control_inst2 : elevator_controller_fsm
	   port map(
            i_clk => w_clk,
            i_reset => fsm_reset,
            is_stopped => sw(14),
            go_up_down => sw(15),
            o_floor => w_floor2
        );
        
    display_MUX : TDM4
     generic map (k_WIDTH => 4)
        port map (
            i_clk   => w_clk_tdm,
            i_reset => clk_reset,  -- clk reset
            i_D3    => x"F", --"1111",  -- unused display: off
            i_D2    => w_floor2,--w_seg,  -- unused display: off -- leave unused switches UNCONNECTED. Ignore any warnings this causes.
            i_D1    => x"F", --"1111",  -- unused display: off
            i_D0    => w_floor1,   -- rightmost display: current floor
            o_data  => w_mux_o,
            o_sel   => an
        );


	clkdiv_inst : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk => clk,
            i_reset => clk_reset,
            o_clk => w_clk
        ); 
        
     clkdiv_inst_TDM : clock_divider
        generic map (k_DIV => 50000)   -- 100Mhz/50,000 /2
            port map (
            i_clk => clk,
            i_reset => clk_reset,
            o_clk => w_clk_tdm
        ); 
	-- CONCURRENT STATEMENTS ----------------------------
	--(btnR or btnU) => w_reset;
	
	--btnU or btnL => 
	
	fsm_reset <= btnR or btnU; -- fsm
	
	clk_reset <= btnU or btnL; -- CLK
	
	 -- LED 15 shows FSM clock tick (helpful debug)
    led(15) <= w_clk;
    led(14 downto 0) <= (others => '0');
    --an <= "1110"; -- all but last anode off for single elevator
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	
	
	-- reset signals
	
end top_basys3_arch;
