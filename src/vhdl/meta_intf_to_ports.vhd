----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/12/2020 12:42:41 PM
-- Design Name: 
-- Module Name: meta_intf_to_ports - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity meta_intf_to_ports is
    port(
    rx_remote_pin_ip: out std_logic_vector(31 downto 0);
    rx_remote_pin_port: out std_logic_vector(15 downto 0);
    rx_local_pin_port: out std_logic_vector(15 downto 0);
    tx_remote_pin_ip: in std_logic_vector(31 downto 0);
    tx_remote_pin_port: in std_logic_vector(15 downto 0);
    tx_local_pin_port: in std_logic_vector(15 downto 0);
    meta_tx_remote_ip: out std_logic_vector(31 downto 0);
    meta_tx_remote_port: out std_logic_vector(15 downto 0);
    meta_tx_local_port: out std_logic_vector(15 downto 0);
    meta_rx_remote_ip: in std_logic_vector(31 downto 0);
    meta_rx_remote_port: in std_logic_vector(15 downto 0);
    meta_rx_local_port: in std_logic_vector(15 downto 0)
    );
    
end meta_intf_to_ports;

architecture Behavioral of meta_intf_to_ports is

begin
    rx_remote_pin_ip <= meta_rx_remote_ip;
    rx_remote_pin_port <= meta_rx_remote_port;
    rx_local_pin_port <= meta_rx_local_port;
    
    meta_tx_remote_ip <= tx_remote_pin_ip;
    meta_tx_remote_port <= tx_remote_pin_port ;
    meta_tx_local_port <= tx_local_pin_port;
end Behavioral;
