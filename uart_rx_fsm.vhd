-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Roman Machala (xmacha86)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
       CLK : in std_logic;
       RST : in std_logic;
       DIN : in std_logic;
       CNT : in std_logic_vector(4 downto 0);   --Prvni counter nam bude pocitat pocet hodinovych signalu, abychom brali "stredovou hodnotu bitu", kdyby doslo k posunuti
       CNT2: in std_logic_vector(3 downto 0)    --Ve druhem counteru se pocita pocet prijatych bitu
    );
end entity;



architecture behavioral of UART_RX_FSM is
--Pro kazdy stav, ktery nam nastane, si vytvorime vlastni datovy typ reprezentujici tento stav, muze nabyvat pouze jednu tuto hodnotu
--WAIT_FOR_FIRST_BIT je stav, ve kterem budeme nastavovat, aby se nam hodnota bitu(0,1) brala ze stredu a ne na zacatku nabezne hrany nebo na konci
type STATE_DATA_TYPE is (IDLE, WAIT_FOR_FIRST_BIT, RECEIVE_ALL_BITS, WAIT_FOR_STOP_BIT, DATA_RECEIVED);
--
signal state : STATE_DATA_TYPE := IDLE;
begin
    process(CLK, RST) begin
        --Musime zajistit, ze se nam proces bude provadet pouze pri nabezne hrane CLK signalu
        if rising_edge(CLK) then

            if RST = '1' then
                --Pokud mame RST nastaveny na 1, vracime se zpet do zacatecni pozice, kde cekame na start bit
                state <= IDLE;
            else
                --Pokud neni nastaveny RST, jsme v jinem stavu. Vsechny stavy ted musime poresit
                case state is
                     
                    when IDLE =>  if DIN = '0' then
                                                    --Pokud se nam na vstupu objevi 0, prepiname do stavu cekani na prvni bit
                                                    state <= WAIT_FOR_FIRST_BIT;
                                                end if;

                    when WAIT_FOR_FIRST_BIT =>  if CNT = "11000" then
                                                    --Pokud na prvnim counteru dostaneme hodnotu 24, jsme ve stredu prvniho bitu
                                                    --8 hodinovych cyklu do stredu start bitu a dalsich 16 do stredu prvniho bitu
                                                    --Pokud by bylo pouze 16, brali bychom hodnoty ze zacatku nabezne hrany, tato implementace by potom nebyla imunni na posuv signalu
                                                    state <= RECEIVE_ALL_BITS;
                                                end if;

                    when RECEIVE_ALL_BITS   =>  if CNT2 = "1000" then
                                                    --Pokud se druhy counter rovna 7, znamena to, ze jsme nacetli vsechny bity a prechazime do stavu cekani na stop bit
                                                    state <= WAIT_FOR_STOP_BIT;
                                                end if;
                    
                    when WAIT_FOR_STOP_BIT  =>  if DIN = '1' then
                                                --Opravit
                                                    state <= DATA_RECEIVED;
                                                end if;
                    
                    when DATA_RECEIVED      =>  state <= IDLE;
                        --Pokud jsme nacetli vsechna poterbna data, prechazime do stavu IDLE, kde cekame na startovaci bit   

                        --Pokud by nastav neurcity stav
                        --Nemelo by nastat
                    when others             => null;

                end case;

            end if

        end if;

    end process;


    

end architecture;
