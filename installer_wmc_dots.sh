#!/bin/bash

# Set repository root
repo_root=""
if [ -d "wmc" ]; then
  repo_root="./wmc"
else
  repo_root="."
fi
echo "repo root is : $repo_root"

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

  if [[ "$choice" == "all" || "$choice" == "ALL" ]]; then
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

  # Copy files matching the resolution
  for dir in "${dirs[@]}"; do
    find "$dir" -type f -name "*${resolution}.png" -exec cp -v {} "$anvil" \;
  done

  echo "Wallpapers with resolution $resolution copied to $anvil"
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

# Main menu
menu() {
  while true; do
    clear
    echo "================================"
    echo "===== Minecraft Wallpapers ====="
    echo "================================"
    echo "1. Temporary install (copy to temp folder)"
    echo "2. Permanent install (copy from temp to wallpapers)"
    echo "3. Clear temp folder"
    echo "[x] exit"
    echo "--------------------------------"
    
    read -p "Choose an option (1-3, or x): " main_choice

    case "$main_choice" in
      1)
        clear
        # Temporary install
        echo ""
        echo "Available folders:"
        options_show
        echo ""
        read -p "Choose folder number or 'all': " folder_choice

        # Validate folder choice
        if [[ "$folder_choice" != "all" && "$folder_choice" != "ALL" && ! "$folder_choice" =~ ^[0-9]+$ ]]; then
          clear
          echo "Invalid choice. Please enter a number or 'all'."
          continue
        fi

        # Get selected directories
        IFS=' ' read -r -a selected_dirs <<< "$(options_chooser "$folder_choice")"

        if [ ${#selected_dirs[@]} -eq 0 ]; then
          clear
          echo "Invalid folder number. Please try again."
          continue
        fi

        # Get available resolutions
        IFS=' ' read -r -a resolutions <<< "$(get_resolutions "${selected_dirs[@]}")"

        if [ ${#resolutions[@]} -eq 0 ]; then
          clear
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

        read -p "Choose resolution number: " res_choice

        # Validate resolution choice
        if [[ "$res_choice" =~ ^[0-9]+$ && "$res_choice" -ge 1 && "$res_choice" -le ${#resolutions[@]} ]]; then
          selected_res="${resolutions[$((res_choice-1))]}"
          copy_to_temp "$selected_res" "${selected_dirs[@]}"
        else
          clear
          echo "Invalid resolution choice."
        fi
        ;;
      2)
        clear
        # Permanent install
        copy_to_install
        ;;
      3)
        clear
        # Clear temp folder
        clear_temp
        ;;
      x|X)
        clear
        echo "Exiting..."
        break
        ;;
      *)
        clear
        echo "Invalid option. Please choose 1, 2, 3, or x."
        ;;
    esac
    echo ""
  done
}

# Run the menu
menu