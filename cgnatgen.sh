#!/bin/bash
# Desenvolvido por Luis Ramalho + ChatGPT
# Projeto Original de Daniel Hoisel
# Licenciado sob a GPL 3.0
versao="1.0"
autor="LeRc"
veros="RouterOS v6.x"
titulo1="# GERADOR DE CGNAT - Autor: $autor - Versão: $versao"
titulo2="[ CGNATGen - Gerador de Script CGNAT ]"

# Função para verificar e instalar o pacote se estiver ausente
verificar_e_instalar_pacote() {
    if ! dpkg -l "$1" &>/dev/null; then
        echo "Pacote $1 não está instalado. Instalando..."
        sudo apt update
        sudo apt install -y "$1"
    fi
}

# Verificar e instalar dialog
verificar_e_instalar_pacote "dialog"

# Verificar e instalar ipcalc
verificar_e_instalar_pacote "ipcalc"

# Verificar se dialog e ipcalc estão instalados antes de continuar
if ! dpkg -l "dialog" &>/dev/null || ! dpkg -l "ipcalc" &>/dev/null; then
    echo "Pacotes necessários não estão instalados. Abortando o script."
    exit 1
fi


if [[ $1 ]]
then
    arquivo=$1
else
    arquivo="mk-cgnat.rsc"
fi

# Inicio dos Dialogos
	entrada=$( dialog --stdout --backtitle "$titulo1" --title "CGNATGEN - (NO NETMAP)" \
    --inputbox "$aviso
                Para definir o nome do arquivo use Ex.: ./cgnatgen.sh arquivo.rsc
                Caso contratio, será gerado como mk-cgnat.rsc

       		 Atualmente o nome é: $arquivo

                Informe o bloco privado/máscara. Ex.: 100.64.0.0/22" 0 0 "100.64.0.0/22")
	if which ipcalc >/dev/null; then
        ipcalc -cbn $entrada | grep Network | cut -f2 -d: | grep $entrada || { dialog --stdout --backtitle "$titulo1" --title "$titulo2" --msgbox "Endereço IP ou de rede inválidos" 0 0; exit; }
    else
        dialog --stdout --sleep 2 --backtitle "$titulo1" --title "$titulo2" --infobox "ipcalc não está instalado. A validação não foi feita" 0 0
    fi
    IFS='/' read -r ipprivado mascaraprivado <<<"$entrada"
    if [[ $mascaraprivado -gt 25 ]]
then
        dialog --stdout --msgbox '
		Quem faz CGNAT com tão poucos IPs?' 8 45
        exit
    fi

# Adicionando diálogo com radiolist para perguntar se deseja informar o nome da interface de uplink
escolha_interface=$(dialog --stdout --backtitle "$titulo1" \
    --title "$titulo2" \
    --radiolist "
	Deseja informar o nome da interface de uplink?" 8 55 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

# Verificar a escolha do usuário
if [[ $escolha_interface == "Sim" ]]; then
    # Se o usuário escolheu Sim, então pedir o nome da interface
    nome_interface=$(dialog --stdout --backtitle "$titulo1" \
        --title "$titulo2" \
        --inputbox "
		Digite o nome da interface de uplink:" 10 45 "sfp.sfpplus1")

    # Verificar se o usuário inseriu um nome para a interface
    if [[ -n $nome_interface ]]; then
			echo "# MASQUERADE" >> $arquivo
			echo "/ip firewall nat " >> $arquivo 
			echo "add action=masquerade chain=src-nat src-address=!$entrada out-interface=$nome_interface" >> $arquivo
			echo "" >> $arquivo 
		else
        echo ""
    fi
else
    # Se o usuário escolheu Não, então informar que o nome da interface não será informado
    echo ""
fi

# Diálogo para adicionar IP de enlace na interface informada
escolha_ip_enlace=$(dialog --stdout --backtitle "$titulo1" \
    --title "$titulo2" \
    --radiolist "
    	Deseja criar um enlace entre o CGNAT e o Concentrador?
	O IP usado sera: 10.10.10.1/30
	Essa é a interface de comunicação entre o seu CGNAT e o concentrador.
" 10 75 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

# Verificar a escolha do usuário e realizar as ações correspondentes
if [[ $escolha_ip_enlace == "Sim" ]]; then
    # Se o usuário escolheu Sim, então pedir o nome da interface de enlace
    nome_int_enlace=$(dialog --stdout --backtitle "$titulo1" \
        --title "$titulo2" \
        --inputbox "
        Digite o nome da interface de enlace:
		Ex: sfp.sfpplus2
		" 10 45 "sfp.sfpplus2")

    # Verificar se o usuário inseriu um nome para a interface
    if [[ -n $nome_int_enlace ]]; then
        echo "# IP de Enlace entre o CGNAT/Concentrador" >> $arquivo
	echo "/ip address" >> $arquivo
	echo "add interface=$nome_int_enlace address=10.10.10.1/30 disabled=no comment=\"IP de Enlace com o Concentrador - CGNATGEN\"" >> $arquivo
        echo "" >> $arquivo
fi
fi

# Adicionando diálogo com checkboxes para ativar diferentes regras
opcoes_regras=$(dialog --stdout --backtitle "$titulo1" \
    --title "$titulo2" \
    --checklist "
	Escolha as regras a serem ativadas:" 8 68 0 \
    "Ativar No Track (RAW)" "Ativar No Track (RAW)" ON \
    "Ativar Blackhole" "Ativar Blackhole" ON \
    "Ativar FastTrack Connection" "Ativar FastTrack Connection" ON)

# Verificando as opções selecionadas
if [[ $opcoes_regras == *"Ativar No Track (RAW)"* ]]; then
    echo "# NO TRACK" >> $arquivo
	echo "/ip firewall raw " >> $arquivo 
	echo "add action=notrack chain=prerouting src-address-list=FORA_CGNAT" >> $arquivo
	echo "add action=notrack chain=prerouting dst-address-list=FORA_CGNAT" >> $arquivo
	echo "" >> $arquivo 
fi

if [[ $opcoes_regras == *"Ativar Blackhole"* ]]; then
	echo "# BLACKHOLE" >> $arquivo
    echo "/ip route" >> $arquivo
    echo "add comment=\"CGNAT Blackhole\" distance=1 dst-address=$entrada type=blackhole" >> $arquivo
    echo "" >> $arquivo
fi

if [[ $opcoes_regras == *"Ativar FastTrack Connection"* ]]; then
    echo "# ATIVA O FASTTRACK" >> $arquivo
	echo "# AVISO: Não usar FastTrack na Routerboard que faz o controle de banda/QoS." >> $arquivo
	echo "/ip firewall filter" >> $arquivo
	echo "add chain=forward action=fasttrack-connection connection-state=established,related" >> $arquivo
	echo "add chain=forward action=accept connection-state=established,related" >> $arquivo
    echo "" >> $arquivo
fi

# Adicionando diálogo com radiolist para perguntar se deseja criar uma address-list para destinos fora do CGNAT
escolha_address_list=$(dialog --stdout --backtitle "$titulo1" \
    --title "$titulo2" \
    --radiolist "
	Deseja criar uma address-list com destinos fora do CGNAT?" 8 65 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

# Verificar a escolha do usuário
if [[ $escolha_address_list == "Sim" ]]; then
    # Se o usuário escolheu Sim, então continuar e pedir o nome da lista
    nome_lista="FORA-CGNAT" # Nome pré-definido para a lista

    # Adicionar diálogo para preencher o nome da lista
    nome_lista=$(dialog --stdout --backtitle "$titulo1" \
        --title "$titulo2" \
        --inputbox "
		Digite o nome da lista (padrão: FORA-CGNAT):" 8 60 "$nome_lista")

    # Se o usuário não preencheu o nome da lista, manter o padrão "FORA-CGNAT"
    if [[ -z $nome_lista ]]; then
        nome_lista="FORA-CGNAT"
    fi
	cmd_lista="dst-address-list=\"$nome_lista\""
	echo "# REGRAS CGNAT" >> $arquivo
	echo "/ip firewall nat" >> $arquivo 
	echo "add chain=srcnat action=jump jump-target=CGNAT src-address=$ipprivado/$mascaraprivado comment=\"CGNATGEN - Do bloco privado: $ipprivado/$mascaraprivado para o(s) bloco(s) publico(s): $entrada - Desative essa regra para desativar o CGNAT\"" >> $arquivo 
	echo "" >> $arquivo
else
	cmd_lista=""
    echo "# REGRAS CGNAT" >> $arquivo
	echo "/ip firewall nat" >> $arquivo 
	echo "add chain=srcnat action=jump jump-target=CGNAT src-address=$ipprivado/$mascaraprivado comment=\"CGNATGEN - Do bloco privado: $ipprivado/$mascaraprivado para o(s) bloco(s) publico(s): $entrada - Desative essa regra para desativar o CGNAT\"" >> $arquivo 
	echo "" >> $arquivo
fi

#  FIM
    entrada=$( dialog --stdout --backtitle "$titulo1" \
                --title "$titulo2" \
                --inputbox "
                PORTAS X BLOCO PÚBLICO NECESSÁRIO
                -----------------------------------
                0500: /$(( $mascaraprivado + 7 )) = $((2**$((32 - $(($mascaraprivado + 7)))))) IPs
                1000: /$(( $mascaraprivado + 6 )) = $((2**$((32 - $(($mascaraprivado + 6)))))) IPs
                2000: /$(( $mascaraprivado + 5 )) = $((2**$((32 - $(($mascaraprivado + 5)))))) IPs
                4000: /$(( $mascaraprivado + 4 )) = $((2**$((32 - $(($mascaraprivado + 4)))))) IPs
                8000: /$(( $mascaraprivado + 3 )) = $((2**$((32 - $(($mascaraprivado + 3)))))) IPs

                Informe o(s) bloco(s) público(s), com a máscara.
                Ex.: 200.200.0.0/25
                Ex.: 200.200.0.0/26 200.200.1.0/27 200.200.2.0/27

                Obs.: Quando informado mais de um bloco, para efeito do cálculo da quantidade de portas,
                será computada a quantidade total de IPs, que deve ser potência na base 2." 0 0 )
	
	quantidadepublico=0
    for blocopublico in ${entrada[*]} 
    do
    IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
    quantidadetotalpublico=$(($quantidadetotalpublico+2**$((32-$mascarapublico))))
    done
    function log2 {
    local l=0
    for (( w=$1-1 ; $w > 0; w >>= 1 )) ; do
        l=$(( $l+1 ))
    done
    echo $l
    }
    mascaratotalpublico=$(( 32 - $(log2 $quantidadetotalpublico) ))
    IFS='.' read -r ipprvpo ipprvso ipprvto ipprvqo <<<"$ipprivado" 
    for blocopublico in ${entrada[*]} 
    do
        if which ipcalc >/dev/null; then
            ipcalc -cbn $blocopublico | grep Network | cut -f2 -d: | grep $blocopublico || { dialog --stdout --backtitle "$titulo1" --title "$titulo2" --infobox "Endereço IP ou de rede inválidos" 0 0 ; exit; }
        else
            dialog --stdout --sleep 2 --backtitle "$titulo1" --title "$titulo2" --infobox "ipcalc não está instalado. A validação não foi feita" 0 0
        fi
        IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
        quantidadepublico=$((2**$((32-$mascarapublico))))
        quantidadeprivado=$((2**$((32-$mascaraprivado))))
        relacao=$(($quantidadeprivado/$quantidadetotalpublico))
        portas=$((64000/$relacao))
        if [[ $portas -lt 500 || $portas -gt 8000 ]]
        then
            aviso1="AVISO: A quantidade mínima e máxima de portas"
            aviso2="recomendada é 500 e 8000, respectivamente."
        fi
        dialog \
                    --cr-wrap \
                    --backtitle "$titulo1"   \
                    --title "$titulo2" \
                    --infobox "
                Gerando o arquivo [ $arquivo ]
                Quantidade de IPs públicos: $quantidadetotalpublico
                Quantidade de IPs privados: $quantidadeprivado
                Relação entre público e privado: 1:$relacao
                Quantidade de portas para cada IP privado: $portas
                Quantidade de regras criadas: $(( ($quantidadetotalpublico * 2) + ($quantidadeprivado * 2) + 1 ))
                $aviso1
                $aviso2
		Script Desenvolvido por: $autor - Versão: [$versao] OS: $veros

		Envie o arquivo para o RouterOS e digite no terminal:
		import file=$arquivo

		Dica: Use IPv6 no Concentrador" 18 70
        mascarajump=$((32-($mascaratotalpublico-$mascaraprivado)))
        IFS='.' read -r ippubpo ippubso ippubto ippubqo <<<"$ippublico"
        comecoporta=1501
        y=1
        while [ $y -le $quantidadepublico ]
        do
            if [[ $ippubqo -gt 255 ]]
            then
                ippubqo=0
                ippubto=$(( $ippubto + 1))
            fi
            if [[ $ipprvqo -gt 255 ]]
            then
                ipprvqo=0
                ipprvto=$(( $ipprvto + 1))
            fi
            echo "add chain=CGNAT action=jump jump-target=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" src-address=\"$ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump\" comment=\"CGNATGEN - Regra de JUMP do bloco privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo\" $cmd_lista" >> $arquivo
ippubqo=$(( $ippubqo + 1 ))
            ipprvqo=$(( $ipprvqo + $relacao ))
            y=$(( $y + 1 ))
        done
    done
    IFS='.' read -r ipprvpo ipprvso ipprvto ipprvqo <<<"$ipprivado"
    for blocopublico in ${entrada[*]} 
    do
        IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
        IFS='.' read -r ippubpo ippubso ippubto ippubqo <<<"$ippublico"
        y=1
        portainicial=$comecoporta
        while [ $y -le $quantidadepublico ]
        do
            if [[ $ippubqo -gt 255 ]]
            then
                ippubqo=0
                ippubto=$(( $ippubto + 1))
            fi
            if [[ $ipprvqo -gt 255 ]]
            then
                ipprvqo=0
                ipprvto=$(( $ipprvto + 1))
            fi
            echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=icmp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump to-address=$ippubpo.$ippubso.$ippubto.$ippubqo comment=\"CGNATGEN - Protocolo: ICMP do bloco privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo\"" >> $arquivo
            x=1
            while [ $x -le $relacao ]
            do
                if [[ $ippubqo -gt 255 ]]
                then
                    ippubqo=0
                    ippubto=$(( $ippubto + 1))
                fi
                if [[ $ipprvqo -gt 255 ]]
                then
                    ipprvqo=0
                    ipprvto=$(( $ipprvto + 1))
                fi
                portafinal=$(( $portainicial + $portas - 1 ))
                echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=tcp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo to-address=$ippubpo.$ippubso.$ippubto.$ippubqo to-ports=$portainicial-$portafinal comment=\"CGNATGEN - Protocolo: TCP do IP Privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo, portas de $portainicial a $portafinal\"" >> $arquivo
                echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=udp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo to-address=$ippubpo.$ippubso.$ippubto.$ippubqo to-ports=$portainicial-$portafinal comment=\"CGNATGEN - Protocolo: UDP do IP Privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo, portas de $portainicial a $portafinal\"">> $arquivo
                portainicial=$(( $portainicial + $portas ))
                ipprvqo=$(( $ipprvqo + 1 ))
                x=$(( $x + 1 ))
            done
            portainicial=1501
            ippubqo=$(( $ippubqo + 1 ))
            y=$(( $y + 1 ))
        done
    done
# Informativo no LOG
echo "" >> $arquivo
echo "# Alertas no Log do RouterOS" >> $arquivo
echo ":log error message=\">> Arquivo ($arquivo) importado com sucesso.\"" >> $arquivo
echo ":log error message=\">> CGNATGen - Gerador de Script CGNAT para $veros.\"" >> $arquivo
echo ":log warning message=\">> IP 10.10.10.1/30 adicionado na interface: $nome_int_enlace\"" >> $arquivo
echo ":log warning message=\">> Configure o IP 10.10.10.2/30 na interface de uplink do seu concentrador.\"" >> $arquivo
    exit
done
else
    echo "Dialog não instalado"
fi
