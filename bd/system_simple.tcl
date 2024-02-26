
################################################################
# This is a generated script based on design: system_simple
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_simple_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# bbox_mem, ist_mem

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu3eg-sfvc784-1-e
   set_property BOARD_PART digilentinc.com:gzu_3eg:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system_simple

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_vip:1.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:fifo_generator:13.2\
xilinx.com:ip:util_vector_logic:2.0\
nycucas:ip:rtcore:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
bbox_mem\
ist_mem\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ray_stream [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:acc_fifo_read_rtl:1.0 ray_stream ]

  set result_stream [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:acc_fifo_write_rtl:1.0 result_stream ]


  # Create ports
  set aclk [ create_bd_port -dir I -type clk aclk ]
  set aresetn [ create_bd_port -dir I -type rst aresetn ]

  # Create instance: bbox_mem_0, and set properties
  set block_name bbox_mem
  set block_cell_name bbox_mem_0
  if { [catch {set bbox_mem_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bbox_mem_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ist_mem_0, and set properties
  set block_name ist_mem
  set block_cell_name ist_mem_0
  if { [catch {set ist_mem_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ist_mem_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_vip_0, and set properties
  set axi_vip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_0 ]
  set_property CONFIG.INTERFACE_MODE {SLAVE} $axi_vip_0


  # Create instance: axi_vip_1, and set properties
  set axi_vip_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_1 ]
  set_property CONFIG.INTERFACE_MODE {SLAVE} $axi_vip_1


  # Create instance: blk_mem_trig, and set properties
  set blk_mem_trig [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_trig ]
  set_property -dict [list \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Read_Width_B {288} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Write_Depth_A {192} \
    CONFIG.Write_Width_A {288} \
    CONFIG.Write_Width_B {288} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_trig


  # Create instance: fifo_bbox_mem_req, and set properties
  set fifo_bbox_mem_req [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_bbox_mem_req ]
  set_property -dict [list \
    CONFIG.Input_Data_Width {34} \
    CONFIG.Input_Depth {512} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Use_Embedded_Registers {false} \
  ] $fifo_bbox_mem_req


  # Create instance: fifo_bbox_mem_resp, and set properties
  set fifo_bbox_mem_resp [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_bbox_mem_resp ]
  set_property -dict [list \
    CONFIG.Input_Data_Width {453} \
    CONFIG.Input_Depth {512} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Use_Embedded_Registers {false} \
  ] $fifo_bbox_mem_resp


  # Create instance: fifo_ist_mem_req, and set properties
  set fifo_ist_mem_req [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_ist_mem_req ]
  set_property -dict [list \
    CONFIG.Input_Data_Width {37} \
    CONFIG.Input_Depth {512} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Use_Embedded_Registers {false} \
  ] $fifo_ist_mem_req


  # Create instance: fifo_ist_mem_resp, and set properties
  set fifo_ist_mem_resp [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_ist_mem_resp ]
  set_property -dict [list \
    CONFIG.Input_Data_Width {293} \
    CONFIG.Input_Depth {512} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Use_Embedded_Registers {false} \
  ] $fifo_ist_mem_resp


  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_1


  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_2


  # Create instance: util_vector_logic_3, and set properties
  set util_vector_logic_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_3 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_3


  # Create instance: util_vector_logic_4, and set properties
  set util_vector_logic_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_4 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_4


  # Create instance: rtcore_0, and set properties
  set rtcore_0 [ create_bd_cell -type ip -vlnv nycucas:ip:rtcore:1.0 rtcore_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net bbox_mem_0_m_axi_ddr [get_bd_intf_pins axi_vip_0/S_AXI] [get_bd_intf_pins bbox_mem_0/m_axi_ddr]
  connect_bd_intf_net -intf_net ist_mem_0_m_axi_ddr [get_bd_intf_pins axi_vip_1/S_AXI] [get_bd_intf_pins ist_mem_0/m_axi_ddr]
  connect_bd_intf_net -intf_net rtcore_0_ray_stream [get_bd_intf_ports ray_stream] [get_bd_intf_pins rtcore_0/ray_stream]
  connect_bd_intf_net -intf_net rtcore_0_result_stream [get_bd_intf_ports result_stream] [get_bd_intf_pins rtcore_0/result_stream]

  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_ports aclk] [get_bd_pins bbox_mem_0/aclk] [get_bd_pins ist_mem_0/aclk] [get_bd_pins axi_vip_0/aclk] [get_bd_pins axi_vip_1/aclk] [get_bd_pins blk_mem_trig/clka] [get_bd_pins blk_mem_trig/clkb] [get_bd_pins fifo_bbox_mem_req/clk] [get_bd_pins fifo_bbox_mem_resp/clk] [get_bd_pins fifo_ist_mem_req/clk] [get_bd_pins fifo_ist_mem_resp/clk] [get_bd_pins rtcore_0/ap_clk]
  connect_bd_net -net aresetn_0_1 [get_bd_ports aresetn] [get_bd_pins bbox_mem_0/aresetn] [get_bd_pins ist_mem_0/aresetn] [get_bd_pins axi_vip_0/aresetn] [get_bd_pins axi_vip_1/aresetn] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net bbox_mem_0_bbox_mem_req_read [get_bd_pins bbox_mem_0/bbox_mem_req_read] [get_bd_pins fifo_bbox_mem_req/rd_en]
  connect_bd_net -net bbox_mem_0_bbox_mem_resp_dout [get_bd_pins bbox_mem_0/bbox_mem_resp_dout] [get_bd_pins fifo_bbox_mem_resp/din]
  connect_bd_net -net bbox_mem_0_bbox_mem_resp_write [get_bd_pins bbox_mem_0/bbox_mem_resp_write] [get_bd_pins fifo_bbox_mem_resp/wr_en]
  connect_bd_net -net blk_mem_trig_doutb [get_bd_pins blk_mem_trig/doutb] [get_bd_pins rtcore_0/trig_s_q0]
  connect_bd_net -net fifo_bbox_mem_resp_dout [get_bd_pins fifo_bbox_mem_resp/dout] [get_bd_pins rtcore_0/bbox_mem_resp_stream_dout]
  connect_bd_net -net fifo_generator_0_dout [get_bd_pins fifo_ist_mem_req/dout] [get_bd_pins ist_mem_0/ist_mem_req_din]
  connect_bd_net -net fifo_generator_0_empty [get_bd_pins fifo_ist_mem_req/empty] [get_bd_pins ist_mem_0/ist_mem_req_empty]
  connect_bd_net -net fifo_generator_0_full [get_bd_pins fifo_ist_mem_req/full] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net fifo_generator_1_empty [get_bd_pins fifo_ist_mem_resp/empty] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net fifo_generator_1_full [get_bd_pins fifo_ist_mem_resp/full] [get_bd_pins ist_mem_0/ist_mem_resp_full]
  connect_bd_net -net fifo_generator_2_dout [get_bd_pins fifo_bbox_mem_req/dout] [get_bd_pins bbox_mem_0/bbox_mem_req_din]
  connect_bd_net -net fifo_generator_2_empty [get_bd_pins fifo_bbox_mem_req/empty] [get_bd_pins bbox_mem_0/bbox_mem_req_empty]
  connect_bd_net -net fifo_generator_2_full [get_bd_pins fifo_bbox_mem_req/full] [get_bd_pins util_vector_logic_3/Op1]
  connect_bd_net -net fifo_generator_3_empty [get_bd_pins fifo_bbox_mem_resp/empty] [get_bd_pins util_vector_logic_4/Op1]
  connect_bd_net -net fifo_generator_3_full [get_bd_pins fifo_bbox_mem_resp/full] [get_bd_pins bbox_mem_0/bbox_mem_resp_full]
  connect_bd_net -net fifo_ist_mem_resp_dout [get_bd_pins fifo_ist_mem_resp/dout] [get_bd_pins rtcore_0/ist_mem_resp_stream_dout]
  connect_bd_net -net ist_mem_0_ist_mem_req_read [get_bd_pins ist_mem_0/ist_mem_req_read] [get_bd_pins fifo_ist_mem_req/rd_en]
  connect_bd_net -net ist_mem_0_ist_mem_resp_dout [get_bd_pins ist_mem_0/ist_mem_resp_dout] [get_bd_pins fifo_ist_mem_resp/din]
  connect_bd_net -net ist_mem_0_ist_mem_resp_write [get_bd_pins ist_mem_0/ist_mem_resp_write] [get_bd_pins fifo_ist_mem_resp/wr_en]
  connect_bd_net -net ist_mem_0_trig_bram_addr [get_bd_pins ist_mem_0/trig_bram_addr] [get_bd_pins blk_mem_trig/addra]
  connect_bd_net -net ist_mem_0_trig_bram_din [get_bd_pins ist_mem_0/trig_bram_din] [get_bd_pins blk_mem_trig/dina]
  connect_bd_net -net ist_mem_0_trig_bram_en [get_bd_pins ist_mem_0/trig_bram_en] [get_bd_pins blk_mem_trig/ena]
  connect_bd_net -net ist_mem_0_trig_bram_we [get_bd_pins ist_mem_0/trig_bram_we] [get_bd_pins blk_mem_trig/wea]
  connect_bd_net -net rtcore_0_bbox_mem_req_stream_din [get_bd_pins rtcore_0/bbox_mem_req_stream_din] [get_bd_pins fifo_bbox_mem_req/din]
  connect_bd_net -net rtcore_0_bbox_mem_req_stream_write [get_bd_pins rtcore_0/bbox_mem_req_stream_write] [get_bd_pins fifo_bbox_mem_req/wr_en]
  connect_bd_net -net rtcore_0_bbox_mem_resp_stream_read [get_bd_pins rtcore_0/bbox_mem_resp_stream_read] [get_bd_pins fifo_bbox_mem_resp/rd_en]
  connect_bd_net -net rtcore_0_ist_mem_req_stream_din [get_bd_pins rtcore_0/ist_mem_req_stream_din] [get_bd_pins fifo_ist_mem_req/din]
  connect_bd_net -net rtcore_0_ist_mem_req_stream_write [get_bd_pins rtcore_0/ist_mem_req_stream_write] [get_bd_pins fifo_ist_mem_req/wr_en]
  connect_bd_net -net rtcore_0_ist_mem_resp_stream_read [get_bd_pins rtcore_0/ist_mem_resp_stream_read] [get_bd_pins fifo_ist_mem_resp/rd_en]
  connect_bd_net -net rtcore_0_trig_s_address0 [get_bd_pins rtcore_0/trig_s_address0] [get_bd_pins blk_mem_trig/addrb]
  connect_bd_net -net rtcore_0_trig_s_ce0 [get_bd_pins rtcore_0/trig_s_ce0] [get_bd_pins blk_mem_trig/enb]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins rtcore_0/ist_mem_req_stream_full_n]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins fifo_bbox_mem_req/srst] [get_bd_pins fifo_bbox_mem_resp/srst] [get_bd_pins fifo_ist_mem_req/srst] [get_bd_pins fifo_ist_mem_resp/srst] [get_bd_pins rtcore_0/ap_rst]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins util_vector_logic_2/Res] [get_bd_pins rtcore_0/ist_mem_resp_stream_empty_n]
  connect_bd_net -net util_vector_logic_3_Res [get_bd_pins util_vector_logic_3/Res] [get_bd_pins rtcore_0/bbox_mem_req_stream_full_n]
  connect_bd_net -net util_vector_logic_4_Res [get_bd_pins util_vector_logic_4/Res] [get_bd_pins rtcore_0/bbox_mem_resp_stream_empty_n]

  # Create address segments
  assign_bd_address -offset 0x000800000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces bbox_mem_0/m_axi_ddr] [get_bd_addr_segs axi_vip_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x000840000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces ist_mem_0/m_axi_ddr] [get_bd_addr_segs axi_vip_1/S_AXI/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


