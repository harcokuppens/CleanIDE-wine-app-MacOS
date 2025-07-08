#!/usr/bin/env python3
import os
import sys
import tempfile # Import the tempfile module

def remove_environment(file_path, environment_name):
    """
    Removes a specified environment block from a configuration file.

    An environment block is defined as starting with a line containing
    'Environment' (preceded by a tab) and ending either when a new
    'Environment' line is encountered or the end of the file is reached.

    Args:
        file_path (str): The path to the configuration file (e.g., 'IDEEnvs').
        environment_name (str): The name of the environment to remove (e.g., 'Gast').
    """
    try:
        # Read all lines from the input file
        with open(file_path, 'r') as f:
            lines = f.readlines()

        output_lines = []  # List to store the lines that will be written to the new file
        current_block_lines = []  # Buffer to hold lines of the current environment block
        
        # Flag to indicate if we are currently inside the environment block to be removed
        in_target_block = False

        for line in lines:
            stripped_line = line.strip()

            # Check if a new 'Environment' block is starting
            if stripped_line == 'Environment':
                # If the previous block was NOT the target, append its buffered lines to output.
                # If it WAS the target, the buffer is effectively discarded.
                if not in_target_block:
                    output_lines.extend(current_block_lines)
                
                # Reset the target block flag for the new environment block
                in_target_block = False
                # Clear the buffer and add the current 'Environment' line to start the new block's buffer
                current_block_lines = [line]
            
            # Check if this line indicates the name of the environment to be removed
            elif stripped_line == f'EnvironmentName:\t{environment_name}':
                # Set the flag to indicate we are now inside the target block
                in_target_block = True
                # Crucially, clear the buffer. This discards the preceding 'Environment' line
                # and this 'EnvironmentName' line, effectively removing the start of the block.
                current_block_lines = []
            
            # For any other lines, add them to the current block's buffer
            else:
                current_block_lines.append(line)
        
        # After the loop, handle the very last buffered block in the file.
        # If the last block was NOT the target, append its buffered lines to the output.
        if not in_target_block:
            output_lines.extend(current_block_lines)

        # --- MODIFIED PART: Using tempfile for a unique temporary file ---
        # Create a unique temporary file in the OS's default temporary directory.
        # mkstemp returns a file descriptor (fd) and the path.
        fd, temp_file_path = tempfile.mkstemp()
        
        try:
            # Open the temporary file using its path (or fd) for writing
            with os.fdopen(fd, 'w') as f:
                f.writelines(output_lines)
            
            # Atomically replace the original file with the modified one
            os.replace(temp_file_path, file_path)

        except Exception as e:
            # If an error occurs during writing or replacing, ensure the temp file is cleaned up
            print(f"Error during temporary file write or replacement: {e}")
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path) # Clean up the temporary file
            raise # Re-raise the exception to be caught by the outer try-except
        # --- END MODIFIED PART ---

        print(f"Successfully processed '{file_path}'. The '{environment_name}' environment has been removed.")

    except FileNotFoundError:
        print(f"Error: The file '{file_path}' was not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# --- Command-line Execution ---
if __name__ == "__main__":
    # Expects two arguments: script_name, file_path, environment_name
    if len(sys.argv) != 3:
        print("Usage: python3 remove_env.py <file_path> <environment_name>")
        print("Example: python3 remove_env.py IDEEnvs Gast")
        sys.exit(1) # Exit with an error code

    file_path = sys.argv[1]
    environment_name = sys.argv[2]

    remove_environment(file_path, environment_name)

