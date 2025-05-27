#! /bin/bash
#Script bash pour automatiser l'installation et la configuration de fail2ban

#Verifier si fail2ban est installé
check=$(rpm -qa fail2ban)  
if [[ ! -z "$check" ]]; then
	echo "La version $check est deja installe"
	exit 1
else
	echo "-----Installation de fail2ban en cours, veuillez patienter--------"
 	dnf update -y --quiet  #faire la mise a jour des depots standards
  	dnf install epel-release #installer ou mettre a jour les depot EPEL
        echo -e "\nMise du systeme termine installation du service en cour..."
	if sudo dnf install fail2ban fail2ban-firewalld -y --quiet; then   
#Demarrer et activer fail2ban
		systemctl start fail2ban
		systemctl enable fail2ban --quiet 

#Creation du fichier jail.local
		touch /etc/fail2ban/jail.local
		read -p "Entrer le bandtime (ex: 1h) : " ban
		read -p "Entrer le findtime (ex: 1h) : " find
		read -p "Entrer le maxretry (ex: 3) : " max
#Contraindre l'utilisateur a rentrer les parametres pour chaque champ
		while [[ -z "$ban" ||  -z "$find" || -z "$max" ]]; do 
			echo "Tous les parametres doivent etres rempli"
			read -p "Entrer le bandtime (ex: 1h) : " ban
                	read -p "Entrer le findtime (ex: 1h) : " find
                	read -p "Entrer le maxretry (ex: 3) : " max
		done
		config="[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = $ban
findtime = $find
maxretry = $max"
		echo -e "$config" > /etc/fail2ban/jail.local   #Entrer dans le fichier jail.local la configuration perso
#renommer le fichier 00-firewalld.conf  en 00-firewalld.local  
		mv /etc/fail2ban/jail.d/00-firewalld.conf /etc/fail2ban/jail.d/00-firewalld.local    
		firewall-cmd --reload --quiet

#Configuration specifique pour le service ssh
		touch /etc/fail2ban/jail.d/sshd.local    #Creer le fichier de configuration pour les connexions ssh
		read -p "Entrer le bantime ssh (ex: 1h) : " bant
		read -p "Entrer le maxretry ssh (ex: 5) : " maxr

		ssh_config="[sshd]
enable = true
bantime = $bant
maxretry = $maxr"
		echo "$ssh_config" > /etc/fail2ban/jail.d/sshd.local
		if systemctl restart fail2ban; then
			echo -e "\nInstallation de fail2ban reussie"
			fail2ban-client status
			fail2ban-client status sshd
		else
			echo -e "\n Une erreur empeche le demarrage de fail2ban verifier les fichier de config"
		fi 
	else
		echo "echec de l'installation de fail2ban verifier votre connection..."
	fi
fi


	

