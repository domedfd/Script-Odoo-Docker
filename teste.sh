#!/usr/bin/env bash
dialog --title "Has creado el dominio primero?" \
--backtitle "Domgroup Sistemas - Creacion de nuevo cliente" \
--yesno "Para que el proceso pueda funcionar es necesario que cries un subdominio con el nombre del cliente antes de inciar el script \"/tmp/foo.txt\"?" 7 60

# Get exit status
# 0 means user hit [yes] button.
# 1 means user hit [no] button.
# 255 means user hit [Esc] key.
response=$?
case $response in
   0) echo "Vamos la.";;
   1) echo "Hasta luego."
      exit 0
      ;;
   255) echo "tecla [ESC] precionda."
      exit 0
      ;;
esac

echo -e "continuando."
