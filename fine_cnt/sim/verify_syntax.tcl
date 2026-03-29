# TCL script for syntax verification

# Create a temporary project for syntax checking
create_project -force fine_counter_syntax_check ./temp_project -part xc7a100tcsg324-1

# Add the source file
add_files ../src/fine_counter_carry4.v

# Set the top module
set_property top fine_counter_carry4 [current_fileset]

# Run synthesis for syntax checking
synth_design -rtl -name rtl_1

# Check for errors
if {[get_msg_config -severity {ERROR}] != ""} {
    puts "ERROR: Syntax errors found"
    exit 1
}

if {[get_msg_config -severity {CRITICAL WARNING}] != ""} {
    puts "WARNING: Critical warnings found"
}

puts "INFO: Syntax check completed successfully"

# Close the project
close_project

exit 0