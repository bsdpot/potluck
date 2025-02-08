#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

case "$RUNTYPE" in

	nostore)
		# import ssh keys for jenkins user or create them?
		if [ -n "$IMPORTKEYS" ]; then
			echo "Importing keys from /root/jenkins.key and /root/jenkins.pub"
			mkdir -p /usr/local/jenkins/.ssh
			chown -R jenkins:jenkins /usr/local/jenkins/.ssh
			chmod 700 /usr/local/jenkins/.ssh
			# cp /root/keys to dest /usr/local/jenkins
			cp -f /root/jenkins.key /usr/local/jenkins/.ssh/id_rsa
			if [ -f /usr/local/jenkins/.ssh/id_rsa ]; then
				chmod 600 /usr/local/jenkins/.ssh/id_rsa
			fi
			cp -f /root/jenkins.pub /usr/local/jenkins/.ssh/id_rsa.pub
			if [ -f /usr/local/jenkins/.ssh/id_rsa.pub ]; then
				chmod 644 /usr/local/jenkins/.ssh/id_rsa.pub
			fi
			chown -R jenkins:jenkins /usr/local/jenkins/.ssh
		else
			echo "Generating keys for jenkins user"
			mkdir -p /usr/local/jenkins/.ssh
			chown -R jenkins:jenkins /usr/local/jenkins/.ssh
			chmod 700 /usr/local/jenkins/.ssh
			# generate keys in /usr/local/jenkins
			su - jenkins -c "ssh-keygen -q -N '' -f /usr/local/jenkins/.ssh/id_rsa -t rsa"
			chown -R jenkins:jenkins /usr/local/jenkins/.ssh
			chmod 600 /usr/local/jenkins/.ssh/id_rsa
		fi
		# enable quick access to remote pot builder host
		if [ -f /usr/local/jenkins/.ssh/known_hosts ]; then
			su - jenkins -c "ssh-keygen -R $BUILDHOST || true"
		fi
		su - jenkins -c "ssh-keyscan -H $BUILDHOST >> /usr/local/jenkins/.ssh/known_hosts"
		# add jenkins user to www group
		/usr/sbin/pw usermod jenkins -G www
		# enable jenkins
		service jenkins enable || true
		;;

	setupstore)
		# copy over /usr/local/jenkins to /mnt/jenkins
		# If the source_file ends in a /, the contents of the directory are copied rather than
		# the directory itself.
		cp -Rpvf /usr/local/jenkins/ /mnt/jenkins/
		chown -R jenkins:jenkins /mnt/jenkins
		# change home directory for jenkins user to /mnt/jenkins
		/usr/sbin/pw usermod -n jenkins -d /mnt/jenkins -q
		# add jenkins user to www group
		/usr/sbin/pw usermod jenkins -G www
		# import ssh keys for jenkins user or create them?
		if [ -n "$IMPORTKEYS" ]; then
			echo "Importing keys from /root/jenkins.key and /root/jenkins.pub"
			mkdir -p /mnt/jenkins/.ssh
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 700 /mnt/jenkins/.ssh
			# cp /root/keys to dest /mnt/jenkins/.ssh
			cp -f /root/jenkins.key /mnt/jenkins/.ssh/id_rsa
			if [ -f /mnt/jenkins/.ssh/id_rsa ]; then
				chmod 600 /mnt/jenkins/.ssh/id_rsa
			fi
			cp -f /root/jenkins.pub /mnt/jenkins/.ssh/id_rsa.pub
			if [ -f /mnt/jenkins/.ssh/id_rsa.pub ]; then
				chmod 644 /mnt/jenkins/.ssh/id_rsa.pub
			fi
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
		else
			echo "Generating keys for jenkins user"
			mkdir -p /mnt/jenkins/.ssh
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 700 /mnt/jenkins/.ssh
			# generate keys in /usr/local/jenkins
			su - jenkins -c "ssh-keygen -q -N '' -f /mnt/jenkins/.ssh/id_rsa -t rsa"
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 600 /mnt/jenkins/.ssh/id_rsa
		fi
		# enable quick access to remote pot builder host
		echo "Adding extra host $BUILDHOST keys"
		if [ -f /mnt/jenkins/.ssh/known_hosts ]; then
			su - jenkins -c "ssh-keygen -R $BUILDHOST || true"
		fi
		su - jenkins -c "ssh-keyscan -H $BUILDHOST >> /mnt/jenkins/.ssh/known_hosts"
		# if an extra host been provided, enable quick ssh access to that host
		if [ -n "$EXTRAHOST" ]; then
			echo "Adding extra host $EXTRAHOST keys"
			su - jenkins -c "ssh-keygen -R $EXTRAHOST || true"
			su - jenkins -c "ssh-keyscan -H $EXTRAHOST >> /mnt/jenkins/.ssh/known_hosts"
		fi
		# set the jenkins home directory to persistent storage at /mnt/jenkins
		sysrc jenkins_home="/mnt/jenkins"
		# enable jenkins
		service jenkins enable || true
		;;

	activestore)
		# set jenkins as owner on /mnt/jenkins
		chown -R jenkins:jenkins /mnt/jenkins
		# change home directory for jenkins user to /mnt/jenkins
		/usr/sbin/pw usermod -n jenkins -d /mnt/jenkins -q
		# add jenkins user to www group
		/usr/sbin/pw usermod jenkins -G www
		# import ssh keys for jenkins user or create them?
		if [ -n "$IMPORTKEYS" ]; then
			echo "Importing keys from /root/jenkins.key and /root/jenkins.pub"
			mkdir -p /mnt/jenkins/.ssh
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 700 /mnt/jenkins/.ssh
			# cp /root/keys to dest /mnt/jenkins/.ssh
			cp -f /root/jenkins.key /mnt/jenkins/.ssh/id_rsa
			if [ -f /mnt/jenkins/.ssh/id_rsa ]; then
				chmod 600 /mnt/jenkins/.ssh/id_rsa
			fi
			cp -f /root/jenkins.pub /mnt/jenkins/.ssh/id_rsa.pub
			if [ -f /mnt/jenkins/.ssh/id_rsa.pub ]; then
				chmod 644 /mnt/jenkins/.ssh/id_rsa.pub
			fi
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
		else
			echo "Generating keys for jenkins user"
			mkdir -p /mnt/jenkins/.ssh
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 700 /mnt/jenkins/.ssh
			# generate keys in /usr/local/jenkins
			su - jenkins -c "ssh-keygen -q -N '' -f /mnt/jenkins/.ssh/id_rsa -t rsa"
			chown -R jenkins:jenkins /mnt/jenkins/.ssh
			chmod 600 /mnt/jenkins/.ssh/id_rsa
		fi
		# enable quick access to remote builder host
		echo "Adding extra host $BUILDHOST keys"
		if [ -f /mnt/jenkins/.ssh/known_hosts ]; then
			su - jenkins -c "ssh-keygen -R $BUILDHOST || true"
		fi
		su - jenkins -c "ssh-keyscan -H $BUILDHOST >> /mnt/jenkins/.ssh/known_hosts"
		# if an extra host been provided, enable quick ssh access to that host
		if [ -n "$EXTRAHOST" ]; then
			echo "Adding extra host $EXTRAHOST keys"
			su - jenkins -c "ssh-keygen -R $EXTRAHOST || true"
			su - jenkins -c "ssh-keyscan -H $EXTRAHOST >> /mnt/jenkins/.ssh/known_hosts"
		fi
		# set the jenkins home directory to persistent storage at /mnt/jenkins
		sysrc jenkins_home="/mnt/jenkins"
		# enable jenkins
		service jenkins enable || true
		;;

	*)
		echo "There is a problem with the RUNTYPE variable. You have input: $RUNTYPE"
		exit 1
		;;

esac
