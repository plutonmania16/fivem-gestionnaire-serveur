#!/bin/bash
clear
if [ "$(whoami)" != "root" ]; then
	echo "Veuillez exécuter ce script en tant que sudo."
	exit 1
fi


if (whiptail --title "Update & Upgrade" --yesno "Voulez-vous mettre à jour votre système ?" 10 60) then
    sudo apt-get update && apt-get upgrade
else
	if [[ $1 == "--no-update" ]]; then
		echo "ok monsieur l'expert. mais c'est de ta faute si quelque chose casse ."
	else
		echo "Désolé, nous ne pouvons pas vous aider alors ."
		exit 1
	fi
	
fi

sudo apt-get install whiptail git xz-utils -y


installlocation=$(whiptail --title "Question" --inputbox "Choisissez un emplacement pour tout installer ." 10 60 /home/fivem/ 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    if [ -d $installlocation ]; then
    	echo "Ce répertoire existe déjà. Veuillez choisir un inexistant ."
    	exit 1;
    fi
else
    echo "Abandon."
    exit 1
fi



## install process

    mkdir -p $installlocation/fxdata
	cd $installlocation/fxdata
	wget https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/4394-572b000db3f5a323039e0915dac64641d1db408e/fx.tar.xz # au point de faire le plus récent. 
	tar xf fx.tar.xz
	rm fx.tar.xz
	cd ..
	mkdir servers
	mkdir managerfiles
	wget https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/manager.sh
	cd ./managerfiles
	wget https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/managerfiles/default-config.cfg
	wget https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/managerfiles/used-ports.txt
	cd ..
	chmod -R 777 $installlocation
	
clear
echo "Le processus d'installation est terminé ."
echo "Pour démarrer le gestionnaire, utilisez 'sudo ${installlocation}manager.sh'."
echo "Veuillez mettre à jour les données FX ."
