#!/bin/bash
clear
if [ "$(whoami)" != "root" ]; then
	echo "Veuillez exécuter ce script en tant que sudo ."
	exit 1
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


### after update stuff
if [ ! -d $DIR/logs ]; then
  mkdir -p $DIR/logs;
fi







OPTION=$(whiptail --title "Slluxx Base de gestionnaire-serveur traduit et correction PlutonMania" --menu "Choisissez votre option " 15 60 5 \
"1" "Gérer les serveurs existants" \
"2" "Ajouter un serveur" \
"3" "Supprimer le serveur" \
"4" "Mettre à jour FXdata" \
"5" "Mettre à jour manager" 3>&1 1>&2 2>&3)

case "$OPTION" in
        1)
            manage=true
            ;;      
        2)
            add=true
            ;;
        3)
            delete=true
            ;;
        4)
            update=true
            ;;
        5)
            updatemanager=true
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

	question=$(whiptail --title "Nom du serveur" --inputbox "Choisissez un nouveau nom de serveur unique. SANS ESPACES! Ce ne sera pas le nom de serveur affiché en ligne ." 10 60 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	
	    if [ -d "./servers/$question" ]; then
	    	whiptail --title "ERROR" --msgbox "Ce nom est déjà utilisé ." 10 60
		./manager.sh
	    fi
	    
	    if echo $question | grep -q " "; then
	    	whiptail --title "ERROR" --msgbox "Veuillez ne pas utiliser d'espaces ." 10 60
			./manager.sh
		fi
	    
	    git clone https://github.com/citizenfx/cfx-server-data.git ./servers/$question
		
		cp /home/fivem/managerfiles/logo.png /home/fivem/servers/$question											  														   

		# creating config file
		port=30120
		while grep "$port" ./managerfiles/used-ports.txt
	    do
	    	port=$(($port+10))
	    done
	    clear
	    
	    port=$(whiptail --title "Choisissez le port du serveur de jeu " --inputbox "Ce port est déjà vérifié et n'est pas utilisé par un serveur de jeu. Veuillez ne changer que si vous savez ce que vous faites !" 10 60 $port 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			port=$port
		else
			echo "Vous avez Annuler ."
			exit 1
		fi
		
		servername=$(whiptail --title "Choisissez le Nom du serveur" --inputbox "Choisissez un nom de serveur. Votre serveur sera répertorié dans le navigateur du serveur avec cela ." 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			servername=$servername
		else
			echo "Vous avez Annuler."
			exit 1
		fi
		
		rcon=$(whiptail --title "Choississez le RCON password" --inputbox "Ce mot de passe est aléatoire ." 10 60 $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1) 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			rcon=$rcon
		else
			echo "Vous avez Annuler."
			exit 1
		fi
	
		license=$(whiptail --title "Entrez votre clee Fivem (obligatoire !)" --inputbox "keymaster.fivem.net" 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			license=$license
		else
			echo "Vous avez choisi Annuler."
			exit 1
		
		
		cat ./managerfiles/default-config.cfg | \
		sed "s/VAR_PORT/$port/" | \
		sed "s/VAR_RCON_PASSWORD/$rcon/" | \
		sed "s/VAR_LICENSE_KEY/$license/" | \
		sed "s/VAR_HOSTNAME/$servername/">>./servers/$question/config.cfg
		
	    echo "$port">>./managerfiles/used-ports.txt
	    whiptail --title "SUCCESS" --msgbox "Votre serveur devrait être installé avec succès ." 10 60
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
			whiptail --title "ERROR" --msgbox "Il n'y a pas de serveur pouvant être supprimé " 10 60
			./manager.sh
		else
			echo "$server n'est pas un répertoire, qu'est-ce qu'il fout ici ?"
			rm -v -f $server
		fi
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	delserver=$(whiptail --title "SUPPRIMER un serveur" --menu "Choisir un serveur à supprimer " 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
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

		whiptail --title "SUCCESS" --msgbox "Votre serveur devrait être supprimé avec succès ." 10 60
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
		    echo "AVANT DE POUVOIR METTRE À JOUR : ARRÊTER  -> $server"
		fi
done
for server in ./servers/*; do
		server="$(echo $server | sed 's,.*/,,')"
		if screen -list | grep -q "$server"; then
		    exit 1
		fi
done


masterfolder="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
newestfxdata="$(curl $masterfolder | grep '<a href' | tail -1 | awk -F[\>\<] '{print $3}')"
# filter valid urls and take last one.

rm -R ./fxdata
mkdir fxdata
cd fxdata
wget ${masterfolder}${newestfxdata}fx.tar.xz 
tar xf fx.tar.xz
rm ./fx.tar.xz
cd ..
chmod -R 777 ./*
whiptail --title "SUCCESS" --msgbox "Mise à jour FX terminée " 10 60
./manager.sh
fi


#
#
# UPDATE MANAGER
#
#


if [[ $updatemanager == "true" ]]; then

managerurl="https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/master/manager.sh"
configurl="https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/master/managerfiles/default-config.cfg"

rm ./manager.sh
wget $managerurl
chmod +x ./manager.sh

cd ./managerfiles
rm ./default-config.cfg
wget $configurl
chmod +x ./default-config.cfg
chmod +x ./manager.sh
cd ..
whiptail --title "SUCCESS" --msgbox "Mise à jour du gestionnaire terminée " 10 60
./manager.sh
fi

#
#
# MANAGE SERVERS
#
#

if [[ $manage == "true" ]]; then


OPTION=$(whiptail --title "Gérer votre serveur " --menu "Choisis une option" 15 60 5 \
"1" "Start" \
"2" "Stop" \
"3" "Restart" \
"4" "Voir Console" 3>&1 1>&2 2>&3)

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
		echo "$server n\'est pas un répertoire, qu\'est-ce qu\'il fout ici ? "
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	startserver=$(whiptail --title "Choisie un serveur" --menu "Choisie un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if ! screen -list | grep -q "$startserver"; then
			cd ./servers/$startserver
			screen -dmS $startserver ../../fxdata/run.sh +exec config.cfg
			cd ../../
			whiptail --title "SUCCESS" --msgbox "Serveur démarré." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "Ce serveur est déjà en cours d\'exécution ." 10 60
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
		echo "$server n\'est pas un répertoire, qu\'est-ce qu\'il fout ici?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	stopserver=$(whiptail --title "Choisie un serveur" --menu "Choisie un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$stopserver"; then
		    	screen -S $stopserver -X at "#" stuff ^C
			whiptail --title "SUCCESS" --msgbox "Serveur Arreté." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "Ce serveur n\'est pas en cours." 10 60
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
		echo "$server n\'est pas un répertoire, qu\'est-ce qu\'il fout ici ?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	
	restart=$(whiptail --title "Choisie un serveur" --menu "Choisie un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$restart"; then
			screen -S $restart -X at "#" stuff ^C
			cd ./servers/$restart
			screen -dmS $restart ../../fxdata/run.sh +exec config.cfg
			cd ../../
			whiptail --title "SUCCESS" --msgbox "Serveur redémarré." 10 60
			./manager.sh
		else
			whiptail --title "ERROR" --msgbox "Ce serveur n\'est pas en cours." 10 60
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
		echo "$server n\'est pas un répertoire, qu\'est-ce qu\'il fout ici ?"
		rm -v -f $server
	    else
		server=${server:${#serverpath}}
		STR[AUX]="${server:1} <-"
		COUNT+=1
		AUX+=1
	    fi
	done
	console=$(whiptail --title "Choisie un serveur" --menu "Choisie un serveur" 15 60 6 ${STR[@]} 3>&1 1>&2 2>&3)
	exitstatus=$?
	if ! [ $exitstatus = 0 ]; then
		./manager.sh
	else
		if screen -list | grep -q "$console"; then
		    whiptail --title "REMEMBER" --msgbox "Pour quitter la console, ne quittez jamais ou utilisez CTRL + C. Cela fermera le serveur ! Au lieu de cela, maintenez la touche CTRL enfoncée et appuyez sur A,D!" 10 60
		    screen -r $console
		    ./manager.sh
		else
			whiptail --title "ERROR" --msgbox "Ce serveur n\'est pas en cours.." 10 60
			./manager.sh
		fi
	fi

fi


fi

