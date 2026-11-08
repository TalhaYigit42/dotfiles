#!/usr/bin/env bash
# Select an area on screen -> the text in it goes to the clipboard (German + English).
if ! command -v tesseract >/dev/null; then notify-send -t 4000 "ocr" "tesseract missing: sudo pacman -S tesseract tesseract-data-deu tesseract-data-eng"; exit 1; fi
geo=$(slurp -d) || exit 0
langs=eng; tesseract --list-langs 2>/dev/null | grep -qx deu && langs=deu+eng
txt=$(grim -g "$geo" - | tesseract stdin stdout -l "$langs" 2>/dev/null | sed '/^\s*$/N;/^\s*\n$/D')
if [ -n "$(printf '%s' "$txt" | tr -d '[:space:]')" ]; then printf '%s' "$txt" | wl-copy; notify-send -t 3000 "ocr" "text copied ($(printf '%s' "$txt" | wc -w) words)"; else notify-send -t 3000 "ocr" "no text found"; fi
