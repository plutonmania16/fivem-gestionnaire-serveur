
###  Gestionnaire de Multiples serveurs Fivem ###

- Cela vous aidera à configurer plusieurs serveurs FX en cinq minutes.
    -  Ajouter des serveurs
    -  Supprimer des serveurs
    -  Démarrer, arrêter et redémarrer les serveurs
    -  Voir la console
    -  Mise à jour vers la dernière version FX.
    -  Guides à travers tout
    -  GUI pour tout.
    

############  Installation Serveur Fivem  ################


1. Mise à jour de debian 10
2. Installation du serveur MySQL
3. Installation de phpMyAdmin
4. Création d’un utilisateur
5. L’installation d’FXserver

- apt install sudo
- apt update
- apt upgrade
- apt install mariadb-client mariadb-server
- apt-get install phpmyadmin
- selectionner apache2
- choissiez 'non' pour la configuration 'dbconfig-common'

Connecter vous a votre Base de donnés, pour voir si tout marche bien !
http://#VOTRE_IP_SERVEUR#/phpmyadmin/
Si phpMyAdmin ne s’affiche pas, utilisez la commande suivante pour créer le lien symbolique:

<ln -s /usr/share/phpmyadmin/ /var/www/html/phpmyadmin>

Si vous avez une erreur lors de la connexion avec l’utilisateur root, faites cela :

sudo mysql -u root
use mysql;
update user set plugin='' where User='root';
flush privileges;
\q

- Creer votre utilisateur :
adduser 'votrenom'

- Copiez et collez ce code pour démarrer l'installation. Vous pouvez alors choisir un chemin d'installation.
- wget https://raw.githubusercontent.com/plutonmania16/fivem-gestionnaire-serveur/main/init.sh && chmod +x ./init.sh && sudo ./init.sh

- Important !!! , Appeller votre dossier comme cela  : "fivem" ce qui donnera : home/fivem 

- Ensuite s'il vous marque :
- Pour démarrer le gestionnaire, utilisez sudo /home/fivemmanager.sh
- corriger par :
- Pour démarrer le gestionnaire, utilisez sudo /home/fivem/manager.sh


- Vous serez obligé de faire une mise à jour et une mise à niveau. Si vous voulez ignorer cela, parce que vous êtes un expert et que vous savez ce que vous faites, passez --no-update

########################
- Pour démarrer le Manager, utilisez 'sudo /home/fivem/manager.sh'

Sans Manager, pour start chaque serveur et tester :
cd /home/fivem/servers/nomdevotreserveur/
bash /home/fivem/fxdata/run.sh +exec /home/fivem/servers/nomdevotreserveur/config.cfg

Pour démarer votre Manager plus vite qu'en tapant la commande , faites un alias :
- Exemple ma ligne de code pour lancer mon manager est [ sudo /home/fivem/manager.sh ]
- Moi je veut, juste qu'en tapant par exemple 'GTA' , le manager s'ouvre !

# Tu fait cette commande : 
- alias GTA='sudo /home/fivem/manager.sh'

° Voilà , plus qu'a écrire 'GTA' pour le lancer !

#################################

- Changer votre password 'root':

SET PASSWORD FOR 'root'@'localhost' = PASSWORD('VotreMotDePasseActuel');
UPDATE mysql.user SET authentication_string = PASSWORD('VotreMotDePasseActuel')   

WHERE User = 'root' AND Host = 'localhost';
update user set password=PASSWORD("NouveauMotDePasse") where User='root';

#################################
- Script créer à la base par @Slluxx
- Traduit en francais et correction et amélioration du Script Obsolete de Slluxx Par plutonmania16
