#! /bin/bash
# Henrique
# v0.8


version=4.5.3
directory=linux-$version

# Faz o download do arquivo de configuração do linux
if [ ! -f "config-linux-$version" ]; then
    echo "Fazendo o download do arquivo de configuração..."
    wget -nc http://www.ic.unicamp.br/~islene/1s2016-mc504/system-call/config-linux-4.5.3
fi
# Faz download da imagem
if [ ! -f "mc504.img" ]; then
    echo "Fazendo download da imagem..."
    wget -nc http://www.ic.unicamp.br/~islene/1s2016-mc504/system-call/mc504.img
fi
# Faz download do kernel
if [ ! -f "linux-$version.tar.xz" ]; then
    echo "Fazendo download do kernel..."
    wget -nc https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$version.tar.xz
fi

# Extrai o kernel
if [ ! -d "$directory" ]; then
    echo "Extraindo o kernel..."
    tar xJf linux-$version.tar.xz
fi

echo "Copiando arquivos para a pasta do linux..."
yes | cp config-linux-$version $directory/.config
yes | cp -rf linux/syscall_32.tbl $directory/arch/x86/entry/syscalls/
yes | cp -rf linux/syscalls.h $directory/include/linux/
yes | cp -rf mycall.c $directory/arch/x86/kernel/
yes | cp -rf linux/Makefile $directory/arch/x86/kernel/

if [ $# -lt 1 ]
then
    echo "
Modo de usar:
    ./execute.sh parametro

    parametro:
    1 : compila o kernel, o arquivo do usuário, e executa
    3 : compila o kernel e executa
    3 : compila o arquivo do usuário e executa
    4 : instruções de compilação
    "
    exit 1
fi

if [ $1 -eq 1 ]
then
    export CCACHE_DIR="/tmp/.ccache"
    cd $directory
    make -j 5 ARCH=i386
    cd ..
    gcc -m32 -static user-space.c -o user-space
    (qemu-system-i386 -hda mc504.img -kernel $directory/arch/i386/boot/bzImage -append 'ro root=/dev/hda' -hdb user-space &)
elif [ $1 -eq 2 ]
then
    export CCACHE_DIR="/tmp/.ccache"
    cd $directory
    make -j 5 ARCH=i386
    cd ..
    (qemu-system-i386 -hda mc504.img -kernel $directory/arch/i386/boot/bzImage -append 'ro root=/dev/hda' -hdb user-space &)
elif [ $1 -eq 3 ]
then
    echo "Compilando codigo do usuário..."
    gcc -m32 -static user-space.c -o user-space
    (qemu-system-i386 -hda mc504.img -kernel $directory/arch/i386/boot/bzImage -append 'ro root=/dev/hda' -hdb user-space &)
else
    echo "
Para compilar o kernel, execute:
    $ cd $directory
    $ make -j 5 ARCH=i386

Se quiser recompilar o programa de usuário:
    $ gcc -m32 -static user-space.c -o user-space
Para executar o qemu:
    $ qemu-system-i386 -hda mc504.img -kernel $directory/arch/i386/boot/bzImage -append 'ro root=/dev/hda' -hdb user-space
"
fi

echo "

Para rodar o programa de usuário no qemu:
    $ cat /dev/hdb > user-program
    $ chmod +x user-program
    $ ./user-program

"
