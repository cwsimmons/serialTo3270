# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "header" -parent ${Page_0}
  ipgui::add_param $IPINST -name "trailer" -parent ${Page_0}


}

proc update_PARAM_VALUE.header { PARAM_VALUE.header } {
	# Procedure called to update header when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.header { PARAM_VALUE.header } {
	# Procedure called to validate header
	return true
}

proc update_PARAM_VALUE.trailer { PARAM_VALUE.trailer } {
	# Procedure called to update trailer when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.trailer { PARAM_VALUE.trailer } {
	# Procedure called to validate trailer
	return true
}


proc update_MODELPARAM_VALUE.header { MODELPARAM_VALUE.header PARAM_VALUE.header } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.header}] ${MODELPARAM_VALUE.header}
}

proc update_MODELPARAM_VALUE.trailer { MODELPARAM_VALUE.trailer PARAM_VALUE.trailer } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.trailer}] ${MODELPARAM_VALUE.trailer}
}

