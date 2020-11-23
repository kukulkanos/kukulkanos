#!/bin/bash
echo "██╗  ██╗██╗   ██╗██╗  ██╗██╗   ██╗██╗     ██╗  ██╗ █████╗ ███╗    ██╗  ██████╗ ███████╗
██║ ██╔╝██║   ██║██║ ██╔╝██║   ██║██║     ██║ ██╔╝██╔══██╗████╗  ██║  ██╔═══██╗██╔════╝
█████╔╝ ██║   ██║█████╔╝ ██║   ██║██║     █████╔╝ ███████║██╔██╗ ██║  ██║   ██║███████╗
██╔═██╗ ██║   ██║██╔═██╗ ██║   ██║██║     ██╔═██╗ ██╔══██║██║╚██╗██║  ██║   ██║╚════██║
██║  ██╗╚██████╔╝██║  ██╗╚██████╔╝███████╗██║  ██╗██║  ██║██║ ╚████║  ╚██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═════╝ ╚══════╝" > /etc/kukulkan.banner
cat /etc/kukulkan.banner
echo "Esto convertirá Debian 10 en KukulkanOS [ENTER=CONTINUAR] [CTR+C=CANCELAR]"
read nothing
#if test -h "$0"
#then
#	export MyNAME=`readlink "$0" | awk -F '/' '{print $(NF)}'` 
#else
#	export MyNAME=`echo "$0" | awk -F '/' '{print $(NF)}'`
#fi
#export MyDIR=`echo "$0" | awk -F $MyNAME '{print $1}'`
MyDIR=/usr/share/kukulkanos/
cd $MyDIR
curl http://debian.kukulkanos.net/apt/debian/doc/kukulkanos.gpg.key | apt-key add -
echo "deb http://debian.kukulkanos.net/apt/debian/ buster main non-free" > /etc/apt/sources.list.d/kukulkanos.list
if ! cat /etc/sources.list | grep debian.net
then apt-add-repository "deb http://http.debian.net/debian/ buster main contrib non-free"
fi
if ! cat /etc/sources.list | grep debian.org
then apt-add-repository "deb http://security.debian.org/ buster/updates main contrib"
fi
apt update
apt install -y wget curl rsync git mc patch iotop gddrescue pigz dkms aufs-tools aufs-dkms cgroupfs-mount 
apt install -y locales iotop gddrescue pigz dkms aufs-tools aufs-dkms cgroupfs-mount build-essential qttools5-dev-tools python3-pyqt5-dbg python3-pyqt5.qsci python3-pyqt5.qtchart python3-pyqt5.qtmultimedia python3-pyqt5.qtopengl-dbg python3-pyqt5.qtopengl python3-pyqt5.qtpositioning python3-pyqt5.qtquick python3-pyqt5.qtsensors python3-pyqt5.qtserialport python3-pyqt5.qtsql python3-pyqt5.qtsvg-dbg python3-pyqt5.qtsvg python3-pyqt5.qtwebchannel python3-pyqt5.qtwebengine python3-pyqt5.qtwebkit python3-pyqt5.qtwebsockets python3-pyqt5.qtx11extras python3-pyqt5.qtxmlpatterns python3-pyqt5.qwt python3-pyqt5 python3-dev python3-venv ca-certificates apt-transport-https lxde lxqt
for file in `ls /etc/import-keys/`
do
	apt-key add $file
done
for repo in kukulkanos kaambesaj
do
	cd /usr/share/$repo/
	if ! git pull
		then 
			cd /tmp
			rm -rf "/tmp/$repo"
			if git clone https://github.com/kukulkanos/$repo.git $repo
				then rsync -av --delete "/tmp/$repo/" "/usr/share/$repo/"
				else cd /usr/share/ && tar -xzvf "$MyDIR/../repos/$repo.tgz"
			fi
	fi
	cd "/usr/share/$repo"
	git pull
	rm "/bin/$repo"
	ln -s "/usr/share/$repo/scripts/$repo.sh" "/bin/$repo"
	chmod +x "/usr/share/$repo/scripts/$repo.sh"
done
cd "$MyDIR"
if cat /etc/inputrc | grep "history-search-backward" | grep "#"
	then 
		patch /etc/inputrc < "$MyDIR/../config/etc/inputrc.patch"
fi
if ! cat /etc/default/grub | grep "spectre_v2"
	then 
		patch /etc/default/grub < "$MyDIR/config/etc/default/grub.patch"
fi
for file in "$MyDIR/../config/keys"/*.pgp
	do cat "$file" | apt-key add -
done
for picture in desktop-background desktop-grub desktop-login-background
do
	if ! test -e /etc/alternatives/$picture.orig
	then
		if ! test -e /etc/alternatives/$picture.orig
			then 
				mv -v /etc/alternatives/$picture /etc/alternatives/$picture.orig
				ln -s /usr/share/kukulkanos/media/backgrounds/default/$picture.png /etc/alternatives/$picture 
		fi
	fi
done
update-grub2
if ! docker version
then
	mkdir /etc/docker
	cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF
	apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
	apt-key fingerprint 0EBFCD88
	#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
	echo "deb https://download.docker.com/linux/debian buster stable" > /etc/apt/sources.list.d/dockerio.list
	apt update
	dpkg -i "$MyDIR"/../applications/docker-ce/*.deb
	apt install -y docker-ce docker-ce-cli containerd.io
	systemctl enable docker
	systemctl start docker
	#images
	if test -e "$MyDIR"/../applets/binary
	then
		cd "$MyDIR"/../applets/binary
		find ./ -iname "*.tgz" |
		while read image
			do 
			INAME=`dirname $image | awk -F '\./' '{print $2}'`:`basename $image | awk -F '.tgz' '{print $1}'`
			echo $image $INAME
			ID=`zcat "$image" | docker load | awk -F ":" '{print $3}'`
			docker tag "$ID" "$INAME"
		done
		cd "$MyDIR"
	fi
fi
if ! docker-compose version
then 
	#apt install -y docker-compose
	if ! curl -L https://github.com/docker/compose/releases/download/1.27.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
		then cp "$MyDIR/../applications/docker-compose/docker-compose-Linux-x86_64 /usr/local/bin/docker-compose"
	fi
	chmod +x /usr/local/bin/docker-compose
fi
docker-compose version

#desactivamos kubernetes por no soportar swap, los usuarios probablemente no tengan suficientes recursos para usar el escritorio sin SWAP, es absurdo.
echo "Kubernetes se ha desactivado por defecto, en lo que encontramos el modo de forzarlo a usar SWAP, para activarlo $0 enable=kubernetes"
if echo "$@" | grep "enable=kubernetes" && ! kubectl version
then 
	# enable bridge netfilter
	modprobe br_netfilter;
	swapoff -a
	echo 'net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/20-bridge-nf.conf;
	echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/30-ip_forward.conf;
	sysctl --system;
	#images
	if test -e "$MyDIR"/../applications/kubernetes/docker.images
	then
		cd "$MyDIR"/../applications/kubernetes/docker.images
		find ./ -iname "*.tgz" |
		while read image
			do 
			INAME=`dirname $image | awk -F '\./' '{print $2}'`:`basename $image | awk -F '.tgz' '{print $1}'`
			echo $image $INAME
			ID=`zcat "$image" | docker load | awk -F ":" '{print $3}'`
			docker tag "$ID" "$INAME"
		done
		cd "$MyDIR"
	fi
	apt install -y ethtool conntrack ebtables 
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
	apt update
	dpkg -i "$MyDIR"/../applications/kubernetes/*.deb
	apt install -y kubelet kubeadm kubectl
	# initialize kubernetes with a Flannel compatible pod network CIDR
	kubeadm init --pod-network-cidr=10.244.0.0/16;
	# setup kubectl
	mkdir -p $HOME/.kube
	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;
	
	# install Flannel
	#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml;
	kubectl apply -f "$MyDIR"/../applications/kubernetes/yaml/kube-flannel.yml
	
	# install Dashboard
	#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml;
	kubectl apply -f "$MyDIR"/../applications/kubernetes/yaml/recommended.yaml
	kubectl delete clusterrolebinding/kubernetes-dashboard;
	kubectl apply -f "$MyDIR"/../applications/kubernetes/yaml/dashboard-admin.yaml;
	
	# get the dashboard secret and display it
	kubectl get secret -n kubernetes-dashboard | grep kubernetes-dashboard-token- | awk '{print $1}' | xargs kubectl describe secret -n kubernetes-dashboard;
	systemctl enable kubelet
fi
if ! vboxmanage --version
	then
		echo "deb http://download.virtualbox.org/virtualbox/debian buster contrib" > /etc/apt/sources.list.d/virtualbox.list
		wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
		apt update
		apt install virtualbox-6.1
fi
cat /etc/kukulkan.banner