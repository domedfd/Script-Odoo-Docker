#!/bin/bash
### Advertencia
dialog --title "Has creado el dominio primero?" \
--backtitle "Domgroup Sistemas - Creacion de nuevo cliente" \
--yesno "Para que el proceso pueda funcionar es necesario que cries un subdominio con el nombre del cliente antes de inciar el script \"$0\"?" 7 60

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


## VARIABLES ##
echo -e "\e[1m1)\e[0m Variables"
CLIENTE=$2
ULTIMOPUERTO=$(docker container list | grep 0.0.0.0: | awk '{print $(NF-1) }' | cut -d "-" -f 1 | cut -d ":" -f 2 | sort | tail -n 1)
let NUEVOPUERTO=$((ULTIMOPUERTO+1))

###############

### Argumentos
case $1 in
   "-h") echo -e "Puedes crear nuevos clienes usando el argumento -n\n Por ejemplo: \e[32m$0 \e[91m-n \e[32mDomgroup\e[0m\n\n Opciones disponibles:\n \e[1m-h\e[0m Ayuda\n \e[1m-v\e[0m Versao\n \e[1m-n\e[0m Nuevo cliente\n"
	 exit 0
         ;;
   "-v") echo -e "Versão \e[32m\e[1m0.0.1\e[0m."
	 exit 0
         ;;
esac

### Verifica se tem argumento
if [ $# -lt 1 ]; then
   echo -e "Digite '$0 \e[32m-h\e[0m' para mas información."
   exit 1
fi

### Verifica se tem primero argumento
if [ "$1" == "-n" ]; then
   echo -e "\e[91m\e[5mAtencion\e[25m\e[0m Creacion de Cliente.\e[0m"
else
   echo -e "$0: Opcion invalida -- '$1'\nPuedes digitar '$0 \e[32m-h\e[0m' para mas información."
   exit 1
fi


### Verifica se tem argumento
if [ $# -lt 2 ]; then
   echo "Falta el el nombre del cliente!"
   exit 1
fi

### Verificando si ya existe el cliente
echo -e "\n\e[1m2)\e[0m Varifica si ya existe cliente"
if docker container ls -a | grep -q $CLIENTE; then
        echo -e "Cliente ya \e[31mexiste\e[0m!"
	exit 1
fi

### Criar pastas de addons, conf(odoo) e pastas de clientes para logs del NGINX
echo -e "\n\e[1m3)\e[0m Creando las carpetas"
mkdir -p /{opt/domgroup/$CLIENTE/extra-addons,var/log/nginx/domgroup/$CLIENTE}

### Criar arquivos para logs do GNINX
echo -e "\n\e[1m4)\e[0m Creando los arquivos de logs"
touch /var/log/nginx/domgroup/$CLIENTE/{access.log,error.log}

### Copiar arquivo de configuracao e addons para pasta do cliente
#echo -e "\nAtencao nao sera posivel copiar o arquivo odoo.conf\n"
#cp ./odoo.conf /opt/domgroup/clientes/$CLIENTE/odoo/
echo -e "\n\e[1m5)\e[0m Copiando los addons"
cp addons.tar.gz /opt/domgroup/$CLIENTE/extra-addons/
cd /opt/domgroup/$CLIENTE/extra-addons/
echo -e "\n\e[1m6)\e[0m Descomprimiendo addons"
tar -zxf addons.tar.gz
cd -

### Verificar y crear el arquivo de conf de nginx
echo -e "\n\e[1m7)\e[0m Adcionando site ne el arquifo default de gninx"
cp modeloNginx /tmp/$CLIENTE.domgroup
sed -i 's/NOMECLIENTE/'"$CLIENTE"'/g' /tmp/$CLIENTE.domgroup
sed -i 's/PUERTO/'"$NUEVOPUERTO"'/g' /tmp/$CLIENTE.domgroup
cat /tmp/$CLIENTE.domgroup >> /etc/nginx/sites-available/default
echo -e "\n\e[1m8)\e[0m Reload nginx"
systemctl reload nginx.service

### Criando certificado ssl
echo -e "\n\e[1m9)\e[0m Creando certificado ssl con cerbot"
yes 2 | certbot --nginx -d $CLIENTE.dgsistema.com
echo -e "\n\e[1m10)\e[0m Reload nginx"
systemctl reload nginx.service

### Verificar e instalar base de datos
echo -e "\n\e[1m11)\e[0m Verifica o instala base de datos"
if docker container ls -a | grep -q "db"; then
        echo "Base de datos ya existe!"
else
        docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres
fi

### Crea el docker de odoo
echo -e "\n\e[1m12)\e[0m Crea Cotainer odoo"
docker run \
-v /opt/domgroup/clientes/$CLIENTE/extra-addons:/mnt/extra-addons \
-p $NUEVOPUERTO:8069 --name $CLIENTE --link db:db -t odoo -- -d $CLIENTE --proxy-mode --without-demo=all
