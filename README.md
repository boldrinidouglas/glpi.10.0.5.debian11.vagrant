# glpi.10.0.5.debian11.vagrant
Implementação via Vagrant do GLPI 10.0.5 em um Debian 11

## Introdução
A ideia aqui é oferecer uma experiência rápida e prática de uma rotina de DevOps com a entrega de uma instância com Debian 11, rodando o GLPI 10.0.5. Utilizei o Vagrant para simplificar a gerência de configuração de software das virtualizações para aumentar a produtividade do desenvolvimento e testes de novas versões.

## Pre-requisitos
* [Vagrant](https://www.vagrantup.com/downloads.html) Instalado
* VirtualBox (para este exemplo utilizei ele, porém poderá utilizar além do VirtualBox outros providers como: KVM, Hyper-V, Docker containers, VMware, e AWS.
* Máquina com pelo menos 4 GB e Processador com no mímimo 4 cores.

## Instalação
1. Crie um diretorio e copie os arquivos lá para dentro (glpifast.sh e Vagrantfile). 
2. Após isso entre com os comandos a seguir:
```vagrant up```
3. Acesse a url: 192.168.1.10 (parametrizavel no Vagrantfile)
4. Entre com as informações de banco: 
SQL server (MariaDB or MySQL): glpi 
SQL user: glpi
SQL password: glpipass

Ainda com dúvidas, de como instalar/acessar o ambiente?
Acesse: https://medium.com/douglasboldrini/vagrant-criando-vms-com-um-comando-ee9f0059e218
