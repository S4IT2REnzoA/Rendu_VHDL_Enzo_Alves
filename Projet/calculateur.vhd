-- ============================================================
--  calculateur.vhd
--  Bloc arithmétique câblé — 4 opérations sur 2 canaux 8 bits
--
--  op_sel : "00" = addition      (résultat sur 9 bits)
--           "01" = soustraction  (résultat saturé à 0 si négatif)
--           "10" = amplification (× 2, résultat sur 9 bits)
--           "11" = atténuation   (÷ 2, LSB perdu par troncature)
--
--  Le résultat est verrouillé dans un registre sur le front
--  montant de data_ready, et reste stable jusqu'à la prochaine
--  acquisition.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculateur is
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;

        -- Données issues de capteurs_sol (8 bits non signés)
        data_i       : in  std_logic_vector(7 downto 0);  -- opérande gauche
        data_j       : in  std_logic_vector(7 downto 0);  -- opérande droit

        -- Sélection d'opération (écrite par la partie logicielle)
        op_sel       : in  std_logic_vector(1 downto 0);

        -- Signal de synchronisation depuis capteurs_sol
        data_ready   : in  std_logic;

        -- Résultat sur 9 bits (bit 8 = overflow / signe)
        resultat     : out std_logic_vector(8 downto 0);

        -- '1' quand le registre de sortie contient un résultat valide
        result_valid : out std_logic
    );
end calculateur;

architecture RTL of calculateur is

    -- Extensions 9 bits pour éviter l'overflow sur addition/ampli
    signal a_ext    : unsigned(8 downto 0);
    signal b_ext    : unsigned(8 downto 0);

    -- Résultat combinatoire (avant registre)
    signal calc_out : std_logic_vector(8 downto 0);

    -- Registre de sortie verrouillé sur data_ready
    signal reg_out  : std_logic_vector(8 downto 0);

    -- Mémorisation du cycle précédent pour détecter le front montant
    signal ready_prev : std_logic;

begin

    -- Extension des opérandes de 8 → 9 bits (MSB = '0')
    a_ext <= '0' & unsigned(data_i);
    b_ext <= '0' & unsigned(data_j);

    -- ── Logique combinatoire ─────────────────────────────────────────────────
    process(op_sel, a_ext, b_ext)
    begin
        case op_sel is

            when "00" =>
                -- Addition : max = 255+255 = 510 → tient sur 9 bits
                calc_out <= std_logic_vector(a_ext + b_ext);

            when "01" =>
                -- Soustraction saturée : si a < b on renvoie 0
                if a_ext >= b_ext then
                    calc_out <= std_logic_vector(a_ext - b_ext);
                else
                    calc_out <= (others => '0');
                end if;

            when "10" =>
                -- Amplification × 2 : décalage gauche de 1 bit
                -- max = 255 × 2 = 510 → tient sur 9 bits
                calc_out <= std_logic_vector(a_ext(7 downto 0) & '0');

            when "11" =>
                -- Atténuation ÷ 2 : décalage droit de 1 bit
                -- bit 8 forcé à '0', LSB perdu par troncature
                calc_out <= '0' & std_logic_vector(a_ext(8 downto 1));

            when others =>
                calc_out <= (others => '0');

        end case;
    end process;

    -- ── Registre de sortie — front montant de data_ready ────────────────────
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            reg_out      <= (others => '0');
            result_valid <= '0';
            ready_prev   <= '0';

        elsif rising_edge(clk) then
            ready_prev <= data_ready;

            -- Verrouillage sur front montant de data_ready
            if (data_ready = '1') and (ready_prev = '0') then
                reg_out      <= calc_out;
                result_valid <= '1';
            end if;

            -- Invalidation quand data_ready redescend à '0'
            if data_ready = '0' then
                result_valid <= '0';
            end if;
        end if;
    end process;

    resultat <= reg_out;

end RTL;