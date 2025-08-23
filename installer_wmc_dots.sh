#!/bin/bash

# Set repository root
repo_root=""
if [ -d "wmc" ]; then
  repo_root="./wmc"
else
  repo_root="."
fi

# Define directories
anvil="$repo_root/temp"
install_folder="$HOME/Pictures/wallpapers"

# Ensure temp and install folders exist
mkdir -p "$anvil" "$install_folder"

# Function to display folder options
options_show() {
  local options=("$repo_root"/*/)
  local num=1
  for dir in "${options[@]}"; do
    # Extract only the folder name
    dir_name=$(basename "$dir")
    echo "$num. $dir_name"
    ((num++))
  done
}

# Function to get folder choice
options_chooser() {
  local choice=$1
  local options=("$repo_root"/*/)
  local selected_dirs=()

  if [[ "$choice" == "all" ]]; then
    for dir in "${options[@]}"; do
      selected_dirs+=("$dir")
    done
  else
    local num=1
    for dir in "${options[@]}"; do
      if [[ $num -eq $choice ]]; then
        selected_dirs+=("$dir")
        break
      fi
      ((num++))
    done
  fi
  echo "${selected_dirs[@]}"
}

# Function to get unique resolutions from selected folders
get_resolutions() {
  local dirs=("$@")
  local resolutions=()
  local res_map=()

  # Collect all resolutions from image files in selected directories
  for dir in "${dirs[@]}"; do
    while IFS= read -r file; do
      # Extract resolution from filename (assuming format like NAME_WIDTHxHEIGHT.png)
      if [[ $file =~ ([0-9]+x[0-9]+)\.png$ ]]; then
        res="${BASH_REMATCH[1]}"
        # Check if resolution is already in the list
        if [[ ! " ${resolutions[*]} " =~ " $res " ]]; then
          resolutions+=("$res")
        fi
      fi
    done < <(find "$dir" -type f -name "*.png")
  done

  # Sort resolutions (optional, for consistent display)
  IFS=$'\n' resolutions=($(sort <<<"${resolutions[*]}"))
  unset IFS

  echo "${resolutions[@]}"
}

# Function to copy wallpapers of a specific resolution to temp folder
copy_to_temp() {
  local resolution="$1"
  shift
  local dirs=("$@")

  # Clear temp folder before copying
  rm -rfv "$anvil"/*
  mkdir -p "$anvil"

  if [[ "$resolution" == "all" ]]; then
    # Copy all PNG files if 'all' is selected
    for dir in "${dirs[@]}"; do
      find "$dir" -type f -name "*.png" -exec cp {} "$anvil" \;
    done
    echo "All wallpapers copied to $anvil"
  else
    # Copy files matching the resolution
    for dir in "${dirs[@]}"; do
      find "$dir" -type f -name "*${resolution}.png" -exec cp {} "$anvil" \;
    done
    echo "Wallpapers with resolution $resolution copied to $anvil"
  fi
}

# Function to copy wallpapers from temp to install folder
copy_to_install() {
  if [ -z "$(ls -A "$anvil")" ]; then
    echo "Temp folder is empty. Please run temporary install first."
    return 1
  fi

  cp -rv "$anvil"/* "$install_folder"/
  echo "Wallpapers copied to $install_folder"
}

# Function to clear temp folder
clear_temp() {
  rm -rfv "$anvil"/*
  echo "Temp folder cleared."
}

# Function to delete matching files from install folder based on temp
delete_matching_from_install() {
  if [ -z "$(ls -A "$anvil")" ]; then
    echo "Temp folder is empty. Nothing to uninstall."
    return 1
  fi

  local found_files=0
  for file in "$anvil"/*; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      dest_file="$install_folder/$filename"
      if [ -f "$dest_file" ]; then
        rm -fv "$dest_file"
        found_files=1
      fi
    fi
  done

  if [ $found_files -eq 0 ]; then
    echo "No matching wallpapers found in $install_folder."
  else
    echo "Matching wallpapers uninstalled successfully."
  fi
}

# Main menu
menu() {
  while true; do
    echo "================================"
    echo "===== Minecraft Wallpapers ====="
    echo "================================"
    echo "[1 /      load] Temporary install (copy to temp folder)"
    echo "[2 /    unload] Clear temp folder"
    echo "[3 /   install] install Permanently (copy from temp to wallpapers)"
    echo "[4 / uninstall] Uninstall matching wallpapers (delete from wallpapers matching temp)"
    echo "[x /      exit] Exit"
    echo ""

    read -p "Choose an option (1-5): " main_choice

    if [[ "$main_choice" == "1" || "$main_choice" == "load" ]];then
        clear
        # Temporary install
        echo ""
        echo "Available folders:"
        options_show
        echo ""
        read -p "Choose folder number or 'all': " folder_choice

        # Get selected directories
        IFS=' ' read -r -a selected_dirs <<< "$(options_chooser "$folder_choice")"

        if [ ${#selected_dirs[@]} -eq 0 ]; then
          echo "Invalid choice. Please try again."
          continue
        fi

        # Get available resolutions
        IFS=' ' read -r -a resolutions <<< "$(get_resolutions "${selected_dirs[@]}")"

        if [ ${#resolutions[@]} -eq 0 ]; then
          echo "No wallpapers found in selected folders."
          continue
        fi

        # Display resolution options
        echo ""
        echo "Available resolutions:"
        local num=1
        for res in "${resolutions[@]}"; do
          echo "$num. $res"
          ((num++))
        done

        read -p "Choose resolution number or 'all': " res_choice

        # Validate resolution choice
        if [[ "$res_choice" == "all" ]]; then
          copy_to_temp "all" "${selected_dirs[@]}"
        elif [[ "$res_choice" =~ ^[0-9]+$ && "$res_choice" -ge 1 && "$res_choice" -le ${#resolutions[@]} ]]; then
          selected_res="${resolutions[$((res_choice-1))]}"
          copy_to_temp "$selected_res" "${selected_dirs[@]}"
        else
          echo "Invalid resolution choice."
        fi
    elif [[ "$main_choice" == "2" || "$main_choice" == "unload" ]];then
        clear
        # Clear temp folder
        clear_temp
    elif [[ "$main_choice" == "3" || "$main_choice" == "install" ]];then
        clear
        # Permanent install
        copy_to_install
    elif [[ "$main_choice" == "4" || "$main_choice" == "uninstall" ]];then
        clear
        # Uninstall matching wallpapers
        delete_matching_from_install
    elif [[ "$main_choice" == "x" || "$main_choice" == "exit" ]];then
        # Exit
        echo "Exiting..."
        break
    else
        echo " X x Invalid Choice !! x X\n ===> plz choose a a number or keyword shown in the menu !"
    fi
  done
}

# Run the menu
menu