.PHONY: build run clean

MS3PATH=".metasploitable3"
MS3CHEFPATH="${MS3PATH}/chef/cookbooks"
CHEF_DEB=".chef.deb"
CHEF_VERSION=15.1.36
CHEF_P_VERSION=${CHEF_VERSION}-1
ARCH=amd64
CHEF_URL="https://packages.chef.io/files/stable/chef/${CHEF_VERSION}/ubuntu/14.04/chef_${CHEF_P_VERSION}_${ARCH}.deb"
CONTAINER_ENGINE := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

all: get-recipies download-chef apply-patch build


clean:
	rm -rf .metasploitable3

get-recipies: 
	[ -d ${MS3PATH} ] || git clone --depth=1 https://github.com/rapid7/metasploitable3 ${MS3PATH}

remove-unwanted-recipies: get-recipies
  ### Disable iptables
	grep -REnl "^include_recipe.*iptables.*" ${MS3CHEFPATH} | xargs perl -0777 -i.old -pe "s/^include_recipe.*iptables.*//g"
	grep -REnl "^iptables_rule.*do" ${MS3CHEFPATH} | xargs perl -0777 -i.old -pe "s/iptables_rule.*do[\s\S]+?end//g"
  ### Disable attempting to bootstrap mysql (it fails since MySQL won't run while the container is building)"
	perl -077 -i.old -pe "s/mysql_service.*do[\s\S]+?end//g" ${MS3CHEFPATH}/metasploitable/recipes/mysql.rb
	grep -REl "mysql.*root" ${MS3CHEFPATH}/ | grep recipes | xargs perl -077 -i.old -pe "s/.*mysql.*root.*//g"
  ### Disable Docker stuff
	perl -077 -i.old -pe "s/include_recipe 'metasploitable::docker'//g" ${MS3CHEFPATH}/metasploitable/recipes/flags.rb
	perl -077 -i.old -pe "s/docker_.*do[\s\S]+?end//g" ${MS3CHEFPATH}/metasploitable/recipes/flags.rb
	### remove /ets/hosts exension
	perl -077 -i.old -pe "s/execute.*add hostname to.*do[\s\S]+?end//g" ${MS3CHEFPATH}/metasploitable/recipes/proftpd.rb
	rm ${MS3CHEFPATH}/metasploitable/recipes/unrealircd.rb


create-patch: remove-unwanted-recipies
	cd ${MS3PATH} && git diff > ../remove-unwanted-recipies.patch && git reset --hard HEAD && git clean -fd

apply-patch: get-recipies
	cd ${MS3PATH} && git apply ../remove-unwanted-recipies.patch > /dev/null 2>&1 || true

download-chef:
	[ -f ${CHEF_DEB} ] || curl -L -o ${CHEF_DEB} ${CHEF_URL} 

build: apply-patch download-chef
	${CONTAINER_ENGINE} build -t nichtsfrei/victim:latest -f Dockerfile .
