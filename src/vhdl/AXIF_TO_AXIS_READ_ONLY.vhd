

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AXIF_TO_AXIS_READ_ONLY is
  generic (
            ID_WIDTH    : integer := 1;
            DATA_WIDTH    : integer := 512;
            BURST_TYPE : std_logic_vector(1 downto 0) := "01" -- 01 - Increment address with each flit, 00 = STATIC ADDRESS for all flits, 10 = LOOP
          );
  port(
        aclk : in std_logic;
        aresetn : in std_logic;
        --MASTER INTERCFACE
        --Write Address Channel
        
        m_axi_awid : out std_logic_vector(ID_WIDTH-1 downto 0);
        m_axi_awaddr : out std_logic_vector(63 downto 0);
        m_axi_awlen : out std_logic_vector(7 downto 0);
        m_axi_awsize : out std_logic_vector(2 downto 0);
        m_axi_awburst : out std_logic_vector(1 downto 0);
        m_axi_awlock : out std_logic_vector(0 downto 0);
        m_axi_awprot : out std_logic_vector(2 downto 0);
        m_axi_awqos : out std_logic_vector(3 downto 0);
        m_axi_awcache : out std_logic_vector(3 downto 0);
        m_axi_awvalid : out std_logic;
        m_axi_awready : in std_logic;
        
        -- AW_tid: in std_logic_vector(ID_WIDTH-1 downto 0); --uncomment to use tid for ID data
        
        -- Write Data Channel
        
        m_axi_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axi_wstrb : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
        m_axi_wlast : out std_logic;
        m_axi_wvalid : out std_logic;
        m_axi_wready : in std_logic;
        
        
        -- Write Response Channel
        
        m_axi_bid : in std_logic_vector(ID_WIDTH-1 downto 0);
        m_axi_bresp : in std_logic_vector(1 downto 0);
        m_axi_bvalid : in std_logic;
        m_axi_bready : out std_logic;
        
        
        -- Read Address Channel
        m_axi_arid : out std_logic_vector(ID_WIDTH-1 downto 0);
        m_axi_araddr : out std_logic_vector(63 downto 0);
        m_axi_arlen : out std_logic_vector(7 downto 0);
        m_axi_arsize : out std_logic_vector(2 downto 0);
        m_axi_arburst : out std_logic_vector(1 downto 0);
        m_axi_arlock : out std_logic_vector(0 downto 0);
        m_axi_arprot : out std_logic_vector(2 downto 0);
        m_axi_arqos : out std_logic_vector(3 downto 0);
        m_axi_arcache : out std_logic_vector(3 downto 0);
        m_axi_arvalid : out std_logic;
        m_axi_arready : in std_logic;
        
        AR_tdata: in std_logic_vector(71 downto 0);
        AR_tvalid: in std_logic;
        AR_tready: out std_logic;
        -- AR_tid: in std_logic_vector(ID_WIDTH-1 downto 0); --uncomment to use tid for ID data
        
        -- Read Data Channel
        m_axi_rid : in std_logic_vector(ID_WIDTH-1 downto 0);
        m_axi_rdata : in std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axi_rresp : in std_logic_vector(1 downto 0);
        m_axi_rlast : in std_logic;
        m_axi_rvalid : in std_logic;
        m_axi_rready : out std_logic;
	
        R_tdata: out std_logic_vector (DATA_WIDTH-1 downto 0);
        R_tdest: out std_logic_vector (1 downto 0);
        R_tvalid: out std_logic;
        R_tlast: out std_logic;
        R_tready: in std_logic
        -- R_tid: in std_logic_vector(ID_WIDTH-1 downto 0); --uncomment to use tid for ID data
      );
end AXIF_TO_AXIS_READ_ONLY;

architecture RTL of AXIF_TO_AXIS_READ_ONLY is
    signal size_param: std_logic_vector (2 downto 0);
begin
    case_32: if DATA_WIDTH = 32 
    generate
    size_param <= "010"; --2^awsize = data size
    end generate;
    case_64: if DATA_WIDTH = 64 
    generate
    size_param <= "011"; --2^awsize = data size
    end generate;
    case_128: if DATA_WIDTH = 128 
    generate
    size_param <= "100"; --2^awsize = data size
    end generate;
    case_256: if DATA_WIDTH = 256 
    generate
    size_param <= "101"; --2^awsize = data size
    end generate;
    case_512: if DATA_WIDTH = 512 
    generate
    size_param <= "110"; --2^awsize = data size
    end generate;
    case_1024: if DATA_WIDTH = 1024 
    generate
    size_param <= "111"; --2^awsize = data size
    end generate;

    m_axi_bready <= '1';
    
    m_axi_awsize <= size_param;

    m_axi_awaddr <= (others => '0');
    m_axi_awlen <= (others => '0');
    m_axi_awburst <= BURST_TYPE;
    m_axi_awlock <= "1";
    m_axi_awprot <= "000";
    m_axi_awqos <= "0000";
    m_axi_awcache <= "0011";
    m_axi_awid <= "0";
    -- m_axi_awid <= AW_tid; -- comment out the line that sets it to 0
    m_axi_awvalid <= '0';
    
    m_axi_araddr <= AR_tdata (63 downto 0);
    m_axi_arlen <= AR_tdata (71 downto 64);
    m_axi_arsize <= size_param;
    m_axi_arburst <= "01";
    m_axi_arlock <= "1";
    m_axi_arprot <= "000";
    m_axi_arqos <= "0000";
    m_axi_arcache <= "0011";
    m_axi_arid <= "1";
    m_axi_arvalid <= AR_tvalid;
    AR_tready <= m_axi_arready;
    -- m_axi_arid <= AR_tid; -- comment out the line that sets it to 1
        
    m_axi_wdata <= (others => '0');
    m_axi_wstrb <= (others => '0');
    m_axi_wlast <= '0';
    m_axi_wvalid <= '0';


    m_axi_rready <= R_tready;
    R_tdata <= m_axi_rdata;
    R_tdest <= m_axi_rresp;
    R_tvalid <= m_axi_rvalid;
    R_tlast <= m_axi_rlast;
    -- R_tid <= m_axi_rid;

    
end RTL;



