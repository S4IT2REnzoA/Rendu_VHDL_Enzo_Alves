LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY robot_cutecar_de0nano IS
    PORT (
        SW : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        CLOCK_50 : IN STD_LOGIC;

        LED : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

        MTR_Sleep_n : OUT STD_LOGIC;
        VCC3P3_PWRON_n : OUT STD_LOGIC;

        MTRR_P : OUT STD_LOGIC;
        MTRR_N : OUT STD_LOGIC;
        MTRL_P : OUT STD_LOGIC;
        MTRL_N : OUT STD_LOGIC;

        DRAM_CLK, DRAM_CKE : OUT STD_LOGIC;
        DRAM_ADDR : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
        DRAM_BA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        DRAM_CS_N, DRAM_CAS_N, DRAM_RAS_N, DRAM_WE_N : OUT STD_LOGIC;
        DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRAM_DQM : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- ADC capteurs
        LTC_ADC_CONVST : OUT std_logic;
        LTC_ADC_SCK    : OUT std_logic;
        LTC_ADC_SDI    : OUT std_logic;
        LTC_ADC_SDO    : IN  std_logic
    );
END robot_cutecar_de0nano;


ARCHITECTURE Structure OF robot_cutecar_de0nano IS

    COMPONENT nios_system
        PORT (
            clk_clk : in std_logic;
            reset_reset_n : in std_logic;
            led_export : out std_logic_vector(7 downto 0);
            sw_export : in std_logic_vector(7 downto 0);

            sdram_wire_addr : out std_logic_vector(12 downto 0);
            sdram_wire_ba : out std_logic_vector(1 downto 0);
            sdram_wire_cas_n : out std_logic;
            sdram_wire_cke : out std_logic;
            sdram_wire_cs_n : out std_logic;
            sdram_wire_dq : inout std_logic_vector(15 downto 0);
            sdram_wire_dqm : out std_logic_vector(1 downto 0);
            sdram_wire_ras_n : out std_logic;
            sdram_wire_we_n : out std_logic;
            sdram_clk_clk : out std_logic;

            motorleft_export : out std_logic_vector(13 downto 0);
            motorright_export : out std_logic_vector(13 downto 0)
        );
    END COMPONENT;


    -- moteurs
    signal motorleft_sig : std_logic_vector(13 downto 0);
    signal motorright_sig : std_logic_vector(13 downto 0);

    -- horloges
    signal clk_40M : std_logic;
    signal clk_2k : std_logic;

    -- capteurs
    signal vect_capt : std_logic_vector(6 downto 0);

    -- seuil capteurs
    signal niveau_seuil : std_logic_vector(7 downto 0);

    -- position ligne
    signal pos_ligne : integer range -6 to 6;

BEGIN


------------------------------------------------
-- activation carte robot
------------------------------------------------

MTR_Sleep_n <= '1';
VCC3P3_PWRON_n <= '0';


------------------------------------------------
-- seuil capteurs
------------------------------------------------

niveau_seuil <= x"70";


------------------------------------------------
-- PLL
------------------------------------------------

PLL_inst : entity work.pll_2freqs
    port map(
        inclk0 => CLOCK_50,
        c0 => clk_40M,
        c1 => clk_2k
    );


------------------------------------------------
-- NIOS
------------------------------------------------

NiosII: nios_system
    PORT MAP (
        clk_clk => CLOCK_50,
        reset_reset_n => KEY(0),

        led_export => open,
        sw_export => SW,

        sdram_wire_addr => DRAM_ADDR,
        sdram_wire_ba => DRAM_BA,
        sdram_wire_cas_n => DRAM_CAS_N,
        sdram_wire_cke => DRAM_CKE,
        sdram_wire_cs_n => DRAM_CS_N,
        sdram_wire_dq => DRAM_DQ,
        sdram_wire_dqm => DRAM_DQM,
        sdram_wire_ras_n => DRAM_RAS_N,
        sdram_wire_we_n => DRAM_WE_N,
        sdram_clk_clk => DRAM_CLK,

        motorleft_export => motorleft_sig,
        motorright_export => motorright_sig
    );


------------------------------------------------
-- PWM moteurs
------------------------------------------------

PWM_inst : entity work.PWM_generation
    port map(
        clk => CLOCK_50,
        reset_n => KEY(0),

        s_writedataL => motorleft_sig,
        s_writedataR => motorright_sig,

        dc_motor_p_R => MTRR_P,
        dc_motor_n_R => MTRR_N,
        dc_motor_p_L => MTRL_P,
        dc_motor_n_L => MTRL_N
    );


------------------------------------------------
-- capteurs sol
------------------------------------------------

capteurs_inst : entity work.capteurs_sol_seuil
    port map(
        clk => clk_40M,
        reset_n => KEY(0),

        data_capture => clk_2k,
        data_readyr => open,
        data0r => open,
        data1r => open,
        data2r => open,
        data3r => open,
        data4r => open,
        data5r => open,
        data6r => open,

        NIVEAU => niveau_seuil,
        vect_capt => vect_capt,

        ADC_CONVSTr => LTC_ADC_CONVST,
        ADC_SCK => LTC_ADC_SCK,
        ADC_SDIr => LTC_ADC_SDI,
        ADC_SDO => LTC_ADC_SDO
    );


------------------------------------------------
-- calcul position ligne
------------------------------------------------

pos_inst : entity work.calcul_position
    port map(
        vect_capt => vect_capt,
        pos_ligne => pos_ligne
    );


------------------------------------------------
-- affichage LED intuitif
------------------------------------------------

process(pos_ligne)
begin
    LED <= "00000000";

    case pos_ligne is
        when -6 => LED <= "10111111"; -- à droiiiiiiiite
        when -5 => LED <= "10011111";
        when -4 => LED <= "10001111";
        when -3 => LED <= "10000111";
        when -2 => LED <= "10000011";
        when -1 => LED <= "10000001";
        when 0  => LED <= "00000000"; -- centre
        when 1  => LED <= "00000001";
        when 2  => LED <= "00000011";
        when 3  => LED <= "00000111";
        when 4  => LED <= "00001111";
        when 5  => LED <= "00011111";
        when 6  => LED <= "00111111";
        when others => LED <= "11111111";
    end case;
end process;


END Structure;