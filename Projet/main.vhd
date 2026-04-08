-- ============================================================
--  main.vhd
--  Entité top-level — DE0-Nano (Cyclone IV EP4CE22F17C6)
--
--  Hiérarchie :
--    main
--    ├── pll_inst       : PLL 50 MHz → 40 MHz (généré par MegaWizard)
--    ├── capteurs_sol   : pilote SPI LTC2308, 7 canaux, 8 bits
--    └── calculateur    : bloc arithmétique câblé (op_sel 2 bits)
--
--  Signaux HW/SW :
--    data_capture  ← GPIO ou touche (impulsion logicielle)
--    op_sel        ← registre écrit par le logiciel (2 bits)
--    result_valid  → IRQ ou GPIO lu par le logiciel
--    resultat      → registre lu par le logiciel (9 bits)
--
--  Nota : la PLL "pll" doit être générée via
--         Tools → MegaWizard Plug-In Manager → ALTPLL
--         Entrée : 50 MHz   Sortie c0 : 40 MHz
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
    port (
        -- ── Horloge et reset ────────────────────────────────
        clk_50      : in  std_logic;                     -- oscillateur DE0-Nano 50 MHz (PIN_R8)
        reset_n     : in  std_logic;                     -- KEY0 actif bas              (PIN_J15)

        -- ── Interface déclenchement (logiciel → HW) ─────────
        data_capture : in  std_logic;                    -- KEY1 ou GPIO                (PIN_E1)

        -- ── Sélection d'opération (logiciel → HW, 2 bits) ───
        op_sel      : in  std_logic_vector(1 downto 0); -- SW1, SW0 ou GPIO

        -- ── Résultat vers logiciel ───────────────────────────
        resultat    : out std_logic_vector(8 downto 0); -- GPIO ou bus mémoire
        result_valid : out std_logic;                   -- IRQ ou GPIO (PIN LED/GPIO)

        -- ── Bus SPI vers LTC2308 ─────────────────────────────
        ADC_CONVSTr : out std_logic;                     -- PIN_R11
        ADC_SCK     : out std_logic;                     -- PIN_R12
        ADC_SDIr    : out std_logic;                     -- PIN_T11
        ADC_SDO     : in  std_logic                      -- PIN_T10
    );
end main;

architecture RTL of main is

    -- ── Déclaration PLL projet précédent ----
    component pll_2freqs
        port (
            inclk0 : in  std_logic;   -- 50 MHz depuis la carte
            c0     : out std_logic    -- 40 MHz vers le design
        );
    end component;

    -- ── Déclaration capteurs_sol ──────────────────────────────────────────────
    component capteurs_sol
        port (
            clk          : in  std_logic;
            reset_n      : in  std_logic;
            data_capture : in  std_logic;
            data_readyr  : out std_logic;
            data0r       : out std_logic_vector(7 downto 0);
            data1r       : out std_logic_vector(7 downto 0);
            data2r       : out std_logic_vector(7 downto 0);
            data3r       : out std_logic_vector(7 downto 0);
            data4r       : out std_logic_vector(7 downto 0);
            data5r       : out std_logic_vector(7 downto 0);
            data6r       : out std_logic_vector(7 downto 0);
            ADC_CONVSTr  : out std_logic;
            ADC_SCK      : out std_logic;
            ADC_SDIr     : out std_logic;
            ADC_SDO      : in  std_logic
        );
    end component;

    -- ── Déclaration calculateur ───────────────────────────────────────────────
    component calculateur
        port (
            clk          : in  std_logic;
            reset_n      : in  std_logic;
            data_i       : in  std_logic_vector(7 downto 0);
            data_j       : in  std_logic_vector(7 downto 0);
            op_sel       : in  std_logic_vector(1 downto 0);
            data_ready   : in  std_logic;
            resultat     : out std_logic_vector(8 downto 0);
            result_valid : out std_logic
        );
    end component;

    -- ── Signaux internes ─────────────────────────────────────────────────────
    signal clk_40     : std_logic;                      -- horloge 40 MHz issue de la PLL

    signal data_ready : std_logic;                      -- fin d'acquisition capteurs_sol

    -- Sorties 8 bits des 7 canaux
    signal data0r     : std_logic_vector(7 downto 0);
    signal data1r     : std_logic_vector(7 downto 0);
    signal data2r     : std_logic_vector(7 downto 0);
    signal data3r     : std_logic_vector(7 downto 0);
    signal data4r     : std_logic_vector(7 downto 0);
    signal data5r     : std_logic_vector(7 downto 0);
    signal data6r     : std_logic_vector(7 downto 0);

begin

    -- ── Instance PLL ─────────────────────────────────────────────────────────
    pll_inst : pll_2freqs
        port map (
            inclk0 => clk_50,
            c0     => clk_40
        );

    -- ── Instance capteurs_sol ─────────────────────────────────────────────────
    capteurs_inst : capteurs_sol
        port map (
            clk          => clk_40,
            reset_n      => reset_n,
            data_capture => data_capture,
            data_readyr  => data_ready,
            data0r       => data0r,
            data1r       => data1r,
            data2r       => data2r,
            data3r       => data3r,
            data4r       => data4r,
            data5r       => data5r,
            data6r       => data6r,
            ADC_CONVSTr  => ADC_CONVSTr,
            ADC_SCK      => ADC_SCK,
            ADC_SDIr     => ADC_SDIr,
            ADC_SDO      => ADC_SDO
        );

    -- ── Instance calculateur ──────────────────────────────────────────────────
    -- data_i = canal 0, data_j = canal 1
    -- Pour changer les opérandes, modifier data0r/data1r ci-dessous
    calc_inst : calculateur
        port map (
            clk          => clk_40,
            reset_n      => reset_n,
            data_i       => data0r,   -- opérande gauche : canal 0
            data_j       => data1r,   -- opérande droit  : canal 1
            op_sel       => op_sel,
            data_ready   => data_ready,
            resultat     => resultat,
            result_valid => result_valid
        );

end RTL;