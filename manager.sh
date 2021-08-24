#!/bin/bash
clear
if [ "$(whoami)" != "root" ]; then
	echo "Veuillez executer ce script en tant que sudo."
	exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


### after update stuff
if [ ! -d $DIR/logs ]; then
  mkdir -p $DIR/logs;
fi







OPTION=$(whiptail --title "Gestion du serveur Fivem" --menu "Choisissez une option" 15 60 5 \
"1" "Gerer les serveurs" \
"2" "Ajouter un serveur" \
"3" "Mettre a jour FxData" \
"4" "Mettre a jour Manager" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            manage=true
            ;;      
        2)
            add=true
            ;;
        # 3)
            # delete=true
            # ;;
        3)
            update=true
            ;;
        4)
            updatemanager=false
            ;;
        *)
            exit 1
esac



#
#
# ADD A SERVER
#
#

if [[ $add == "true" ]]; then

	question=$(whiptail --title "Nom interne" --inputbox "Choisissez un nouveau nom de serveur. SANS ESPACES ! Ce ne sera pas le nom du serveur affiche en ligne." 10 60 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	
	    if [ -d "./servers/$question" ]; then
	    	whiptail --title "ERREUR" --msgbox "Ce nom est deja utilise." 10 60
		./manager.sh
	    fi
	    
	    if echo $question | grep -q " "; then
	    	whiptail --title "ERREUR" --msgbox "Veuillez ne pas utiliser d'espaces." 10 60
			./manager.sh
		fi
	    
	    git clone https://github.com/citizenfx/cfx-server-data.git ./servers/$question
	    #copies the Host-Heberg logo in the server folder
	    cp /home/fivem/managerfiles/logo.png /home/fivem/servers/$question

		# creating config file
		port=30120
		while grep "$port" ./managerfiles/used-ports.txt
	    do
	    	port=$(($port+10))
	    done
	    clear
	    
	    port=$(whiptail --title "Choisissez le port du serveur" --inputbox "Ce port est deja verifie et n'est pas utilise par un serveur de jeux. N'oubliez pas de demander au support d'ouvrir le port associe." 10 60 $port 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			port=$port
		else
			echo "Vous avez choisi Annuler."
			exit 1
		fi
		
		servername=$(whiptail --title "Choisissez le nom du serveur de jeux" --inputbox "Choisissez un nom de serveur. Votre serveur sera repertorie dans le navigateur de serveur en ligne." 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			servername=$servername
		else
			echo "Vous avez choisi Annuler."
			exit 1
		fi
		
		rcon=$(whiptail --title "Choisissez le mot de passe RCON" --inputbox "Ce mot de passe est aleatoire." 10 60 $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1) 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			rcon=$rcon
		else
			echo "Vous avez choisi Annuler."
			exit 1
		fi
		
		license=$(whiptail --title "Entrez votre clee Fivem (obligatoire !)" --inputbox "keymaster.fivem.net" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			license=$license
		else
			echo "Vous avez choisi Annuler."
			exit 1
		fi

		
		
		cat ./managerfiles/default-config.cfg | \
		sed "s/VAR_PORT/$port/" | \
		sed "s/VAR_RCON_PASSWORD/$rcon/" | \
		sed "s/VAR_LICENSE_KEY/$license/" | \
		sed "s/VAR_HOSTNAME/$servername/">>./servers/$question/config.cfg
		
	    echo "$port">>./managerfiles/used-ports.txt
	    whiptail --title "SUCCES" --msgbox "Votre serveur a ete installe avec succes." 10 60
	    ./manager.sh
	else
	    ./manager.sh
	fi

fi

#
#
# DELETE A SERVER
#
#

if [[ $delete == "true" ]]; then


	COUNT=1
	AUX=0;
	serverpath="./servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		if [ $server == "./servers/*" ]; then
			whiptail --title "ERREUR" --msgbox "Aucun serveur ne peut etre supprime" 10 60
			./manager.sh
		else
			echo "$server is not a directory, what the hell is it doing here?"
			rm -v -f $server
		fi
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	delserver=$(whiptail --title "SUPPRIMER un serveur" --menu "Choisissez un serveur a supprimer" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		# read out the port
		port="$(grep 'endpoint_add_tcp' ./servers/$delserver/config.cfg | sed 's/endpoint_add_tcp //' | tr -d \" | sed 's/.*://')"
		sed -i "/$port/d" ./managerfiles/used-ports.txt
		cd ./servers
		rm -f -r ./$delserver
		cd ..

		whiptail --title "SUCCES" --msgbox "Votre serveur a ete supprime avec succes." 10 60
		./manager.sh
	fi
fi

#
#
# UPDATE FXDATA
#
#

if [[ $update == "true" ]]; then

for server in ./servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    echo "BEFORE YOU CAN UPDATE: SHUTDOWN -> $server"
		fi
done
for server in ./servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    exit 1
		fi
done


#masterfolder="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
#newestfxdata="$(curl $masterfolder | grep '<a href' | tail -1 | awk -F[\>\<] '{print $3}')"
# filter valid urls and take last one.

rm -R ./fxdata
mkdir fxdata
cd fxdata
wget https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/4304-e6242ce0c0aab30473a76eac9ff46466eb82e7de/fx.tar.xz # Mettre a jour avec votre artifact
tar xf fx.tar.xz
rm ./fx.tar.xz
cd ..
chmod -R 777 ./*
whiptail --title "SUCCES" --msgbox "Mise a jour de FX terminee" 10 60
./manager.sh
fi


#
#
# UPDATE MANAGER
#
#


if [[ $updatemanager == "true" ]]; then

managerurl="https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/manager.sh"
configurl="https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/managerfiles/default-config.cfg"
rm ./manager.sh
wget $managerurl
chmod +x ./manager.sh

cd ./managerfiles
rm ./default-config.cfg
wget $configurl
chmod +x ./default-config.cfg
chmod +x ./manager.sh
cd ..
whiptail --title "SUCCES" --msgbox "Mise a jour du Manager terminee" 10 60
./manager.sh
fi

#
#
# MANAGE SERVERS
#
#

if [[ $manage == "true" ]]; then


OPTION=$(whiptail --title "Gestion du serveur" --menu "Choisissez une option" 15 60 5 \
"1" "Demarrer" \
"2" "Stopper" \
"3" "Redemarrer" \
"4" "Acces a la console" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            start=true
            ;;      
        2)
            stop=true
            ;;
        3)
            restart=true
            ;;
        4)
            console=true
            ;;
        *)
            exit 1
esac

if [[ $start == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	startserver=$(whiptail --title "Choisissez un serveur" --menu "Choisissez un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if ! screen -list | grep -q "$startserver"; then
			cd ./servers/$startserver
			screen -dmSL $startserver /home/fivem/fxdata/run.sh +exec config.cfg
			cd ../../
			whiptail --title "SUCCES" --msgbox "Le serveur a demarre." 10 60
			./manager.sh
		else
			whiptail --title "ERREUR" --msgbox "Ce serveur est deja en cours d'exécution." 10 60
			./manager.sh
		fi
	fi

fi


if [[ $stop == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	stopserver=$(whiptail --title "Choisissez un serveur" --menu "Choisissez un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$stopserver"; then
		    	screen -S $stopserver -X at "#" stuff ^C
			whiptail --title "SUCCES" --msgbox "Le serveur a été arrete." 10 60
			./manager.sh
		else
			whiptail --title "ERREUR" --msgbox "Le serveur n'est pas en cours d'execution." 10 60
			./manager.sh
		fi
	fi


fi


if [[ $restart == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	
	restart=$(whiptail --title "Choisissez un serveur" --menu "Choisissez un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$Redemarrer"; then
			screen -S $restart -X at "#" stuff ^C
			cd ./servers/$restart
			screen -dmSL $restart ../../fxdata/run.sh +exec config.cfg
			cd ../../
			whiptail --title "SUCCES" --msgbox "Redemarrage du serveur." 10 60
			./manager.sh
		else
			whiptail --title "ERREUR" --msgbox "Le serveur n'est pas en cours d'execution." 10 60
			./manager.sh
		fi
	fi
fi


if [[ $console == "true" ]]; then

	COUNT=1
	AUX=0;
	serverpath="./servers"
	for server in $serverpath/*; do
	    if ! [ -d $server ]; then
		echo "$server is not a directory, what the hell is it doing here?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	console=$(whiptail --title "Choisissez un serveur" --menu "Choisissez un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$console"; then
		    whiptail --title "RAPPELLES !" --msgbox "Pour quitter la console, ne jamais utiliser la commande CTRL + C. Cela fermera le serveur ! Au lieu de cela utiliser CTRL + A et D !" 10 60
		    sudo screen -r $console
		    ./manager.sh
		else
			whiptail --title "ERREUR" --msgbox "Le serveur n'est pas en cours d'execution." 10 60
			./manager.sh
		fi
	fi

fi


fi

