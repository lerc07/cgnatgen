#!/bin/bash
# Desenvolvido e Remodelado por Luis Ramalho + ChatGPT
# Projeto Original de Daniel Hoisel
# Licenciado sob a GPL 3.0
versao="2.0"
autor="LeRc"
veros="RouterOS v6.x/v7.x"
titulo1="\Z7# GERADOR DE CGNAT - Autor: $autor - Versão: $versao\Zn"
titulo2="\Z7[ CGNATGen - Gerador de Script CGNAT ]\Zn"

# Função para verificar e instalar o pacote se estiver ausente
verificar_e_instalar_pacote() {
    if ! dpkg -l "$1" &>/dev/null; then
        echo "Pacote $1 não está instalado. Instalando..."
        sudo apt update
        sudo apt install -y "$1"
    fi
}

# Verificar e instalar dialog e ipcalc
verificar_e_instalar_pacote "dialog"
verificar_e_instalar_pacote "ipcalc"

# Verificar se dialog e ipcalc estão instalados antes de continuar
if ! dpkg -l "dialog" &>/dev/null || ! dpkg -l "ipcalc" &>/dev/null; then
    echo "Pacotes necessários não estão instalados. Abortando o script."
    exit 1
fi

# Função para verificar se um IP pertence a uma rede privada
is_private_ip() {
    local ip="$1"
    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
    # 10.0.0.0/8
    if [ "$o1" -eq 10 ]; then
         return 0
    fi
    # 172.16.0.0/12 (172.16.0.0 a 172.31.255.255)
    if [ "$o1" -eq 172 ] && [ "$o2" -ge 16 ] && [ "$o2" -le 31 ]; then
         return 0
    fi
    # 192.168.0.0/16
    if [ "$o1" -eq 192 ] && [ "$o2" -eq 168 ]; then
         return 0
    fi
    # 100.64.0.0/10 (100.64.0.0 a 100.127.255.255)
    if [ "$o1" -eq 100 ] && [ "$o2" -ge 64 ] && [ "$o2" -le 127 ]; then
         return 0
    fi
    return 1
}

# Verifica se o diretório "arquivos" existe; se não, cria-o
if [ ! -d "arquivos" ]; then
    mkdir -p arquivos
fi

# Define a data e a hora para o nome do arquivo
hora=$(date +"%H-%M")
data=$(date +"[%d-%m-%Y]")

if [[ $1 ]]; then
    arquivo=$1
else
    arquivo="arquivos/cgnat-$hora-$data.rsc"
fi

# Início dos diálogos
entradap=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" \
    --inputbox "
	Para definir o nome do arquivo use Ex.: 
\Z1./cgnatgen.sh arquivo.rsc\Zn

Caso contrário, será gerado como \Z1mk-cgnat.rsc\Zn
Atualmente o nome é: [ \Z4$arquivo\Zn ]

\Z2Informe o bloco privado/máscara. Ex.: 100.64.0.2/22\Zn

Nesse caso, o IP \Z1100.64.0.1\Zn ficará fora do CGNAT para uso do IP LOCAL." 0 0 "100.64.0.2/22")

if [[ -z "$entradap" ]]; then
    dialog --colors --stdout --msgbox "\Z1Entrada inválida. O script será encerrado.\Zn" 6 50
    exit 1
fi

if ! ipcalc -cbn "$entradap" | grep -q "Network"; then
    dialog --colors --stdout --msgbox "\Z1Endereço IP ou de rede inválidos\Zn" 6 50
    exit 1
fi

IFS='/' read -r ipprivado mascaraprivado <<<"$entradap"
if [[ ! $mascaraprivado =~ ^[0-9]+$ ]] || [[ $mascaraprivado -gt 25 ]]; then
    dialog --colors --stdout --msgbox "\Z1Máscara inválida ou muito pequena para CGNAT.\Zn" 6 50
    exit 1
fi

# Monta a tabela com IPs
while true; do
    entrada=$( dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --inputbox "
\Z1+-------------+--------------+----------------+\Zn
 \Z2PORTAS: 0500 | Máscara: /$(( mascaraprivado + 7 )) | Quant. IPs: 00$(( 2**(32 - (mascaraprivado + 7)) ))\Zn
 \Z2PORTAS: 1000 | Máscara: /$(( mascaraprivado + 6 )) | Quant. IPs: 0$(( 2**(32 - (mascaraprivado + 6)) ))\Zn
 \Z2PORTAS: 2000 | Máscara: /$(( mascaraprivado + 5 )) | Quant. IPs: 0$(( 2**(32 - (mascaraprivado + 5)) ))\Zn
 \Z2PORTAS: 4000 | Máscara: /$(( mascaraprivado + 4 )) | Quant. IPs: 0$(( 2**(32 - (mascaraprivado + 4)) ))\Zn
 \Z2PORTAS: 8000 | Máscara: /$(( mascaraprivado + 3 )) | Quant. IPs: $(( 2**(32 - (mascaraprivado + 3)) ))\Zn
\Z1+-------------+--------------+----------------+\Zn

Informe o(s) bloco(s) público(s), com a máscara.
Ex.: 200.200.0.0/25
Ex.: 200.200.0.0/26 200.200.1.0/27 200.200.2.0/27

\Z1Obs.:\Zn \Z2Quando informado mais de um bloco, para efeito 
do cálculo da quantidade de portas, será computada a 
quantidade total de IPs, que deve ser potência na base 2.\Zn" 0 0 "")

    # Verifica se a entrada está vazia
    if [[ -z "$entrada" ]]; then
        dialog --colors --stdout --msgbox "\Z1Entrada inválida. Informe pelo menos um bloco de IP público.\Zn" 5 65
        continue
    fi

    # Normaliza a variável 'entrada'
    entrada=$(echo "$entrada")
    
    # Valida cada bloco informado utilizando ipcalc e garantindo que não seja IP privado
    invalido=false
    for bloco in $entrada; do
        if ! ipcalc -cbn "$bloco" | grep -q "Network"; then
            invalido=true
            break
        fi
        IFS='/' read -r ip mascarapublico <<< "$bloco"
        if is_private_ip "$ip"; then
            invalido=true
            break
        fi
    done

    if $invalido; then
        dialog --colors --stdout --msgbox "\Z1IP Público inválido ou pertence a uma rede privada.\Zn" 5 60
    else
        break
    fi
done

# Diálogo para perguntar se deseja informar o nome da interface de uplink
escolha_interface=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --radiolist "
	\Z2Deseja informar o nome da interface de uplink?\Zn" 8 65 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

if [[ $escolha_interface == "Sim" ]]; then
    nome_interface=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --inputbox "
	\Z2Digite o nome da interface de uplink:\Zn" 8 65 "sfp.sfpplus1")
    if [[ -n "$nome_interface" ]]; then
        echo "# MASQUERADE" >> "$arquivo"
        echo "/ip firewall nat" >> "$arquivo" 
        echo "add action=masquerade chain=src-nat src-address=!$entradap out-interface=$nome_interface" >> "$arquivo"
        echo "" >> "$arquivo" 
    fi
fi

# Diálogo para criar um enlace entre o CGNAT e o Concentrador
escolha_ip_enlace=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --radiolist "
	\Z2Deseja criar um enlace entre o CGNAT e o Concentrador?\Zn
	\Z2Nesse caso, será inserido o IP \Z110.10.10.1/30\Zn na RB CGNAT
	e o \Z1IP 10.10.10.2/30\Zn na RB Concentrador." 10 65 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

if [[ "$escolha_ip_enlace" == "Sim" ]]; then
    nome_int_enlace=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --inputbox "
	\Z2Digite o nome da interface de enlace:\Zn" 8 65 "sfp.sfpplus2")
    if [[ -n "$nome_int_enlace" ]]; then
        echo "# IP de Enlace entre o CGNAT/Concentrador" >> "$arquivo"
        echo "/ip address" >> "$arquivo"
        echo "add interface=$nome_int_enlace address=10.10.10.1/30 disabled=no comment=\"IP de Enlace com o Concentrador - CGNATGEN\"" >> "$arquivo"
        echo "" >> "$arquivo"
    fi
fi

# Nova sequência de telas para ativar regras:
# Primeira tela: Ativar FastTrack Connection
ativar_fasttrack=$(dialog --colors --stdout --backtitle "$titulo1" \
    --title "$titulo2" \
    --radiolist "
\Z2Deseja ativar o FastTrack Connection?\Zn

\Z1O Fasttrack Connection serve para melhorar o desempenho de conexões que não precisam de inspeção detalhada. 
Ele é ideal para conexões confiáveis (como de usuários internos com navegação comum), porque:
\Z4- Aumenta a velocidade de throughput (mais Mbps/Gbps).
- Diminui a carga da CPU, pois as conexões são 'desviadas' do caminho de processamento completo.\Zn

\Z1Quanto NÃO utilizar o Fasttrack Connection?\Zn
\Z4- Se você usa queue trees (QoS avançado) baseado em interface ou marcações (Controle de Banda);
- Se você precisa monitorar detalhadamente o tráfego (como com Netflow, Traffic Accounting, Layer7, DPI, etc);
- Se usa firewall com inspeção profunda (tipo IDS/IPS, análise por porta/destino);\Zn " 20 115 2 \
    "Sim" "Ativar FastTrack Connection" ON \
    "Não" "Não ativar FastTrack Connection" OFF)

if [[ "$ativar_fasttrack" == "Sim" ]]; then
    echo "# ATIVA O FASTTRACK" >> "$arquivo"
    echo "# AVISO: Não usar FastTrack na Routerboard que faz o controle de banda/QoS." >> "$arquivo"
    echo "/ip firewall filter" >> "$arquivo"
    echo "add chain=forward action=fasttrack-connection connection-state=established,related" >> "$arquivo"
    echo "add chain=forward action=accept connection-state=established,related" >> "$arquivo"
    echo "" >> "$arquivo"

    # Segunda tela: Ativar No Track (RAW) com explicação adicional
    ativar_notrack=$(dialog --colors --stdout --backtitle "$titulo1" \
       --title "$titulo2" \
       --radiolist "
	   \Z2Deseja ativar o No Track (RAW)?\Zn
\Z3
A função no-track no firewall do MikroTik, especificamente na chain (RAW), serve para desativar 
o rastreamento de conexões para determinados pacotes antes que sejam processados pelo conntrack.
O C.T. é importante para diversas funções do firewall, como NAT, filtragem por estado de conexão e QoS. 

No entanto, há situações em que desativar o rastreamento pode trazer benefícios:

Melhorar o Desempenho = O rastreamento de conexões consome recursos do processador e da memória. 
Se há tráfego que não precisa ser rastreado (como pacotes multicast, broadcast ou pacotes internos
de roteamento), o uso do no-track pode reduzir a carga no sistema.

Tratar pacotes sensíveis sem delay = O rastreamento pode adicionar um pequeno atraso ao processamento
de pacotes. Desativá-lo pode ser útil para protocolos em tempo real como VoIP (SIP, RTP), onde a latência é crítica.

Pacotes que não precisam de NAT ou regras de estado = Se você tem pacotes que não precisam de NAT ou
regras de filtragem com base em estado (como pacotes IPSec ou tráfego entre interfaces específicas),
pode desativar o rastreamento.

Observação importante:
Se um pacote passar pelo firewall com no-track, ele não pode ser filtrado pelas chains input, forward 
ou output do firewall, pois não terá um estado de conexão associado.\Zn

\Z1Para evitar problemas, use com cautela e apenas quando realmente necessário.\Zn" 32 110 0 \
         "Sim" "Ativar No Track (RAW)" ON \
         "Não" "Não ativar No Track (RAW)" OFF)
    if [[ "$ativar_notrack" == "Sim" ]]; then
         echo "# NO TRACK" >> "$arquivo"
         echo "/ip firewall raw" >> "$arquivo" 
         echo "add action=notrack chain=prerouting src-address-list=FORA_CGNAT" >> "$arquivo"
         echo "add action=notrack chain=prerouting dst-address-list=FORA_CGNAT" >> "$arquivo"
         echo "" >> "$arquivo" 
    fi
fi

# Se o usuário optou por criar o enlace e informou o IP de enlace, perguntar se deseja adicionar as Rotas IPs CGNAT
if [[ "$escolha_ip_enlace" == "Sim" && -n "$nome_int_enlace" ]]; then
    adiciona_rota=$(dialog --colors --stdout --backtitle "$titulo1" \
       --title "$titulo2" \
       --radiolist "\Z2
	   Deseja adicionar a Rota de destino \Z1($ipprivado/$mascaraprivado)\Zn para o Gateway (\Z110.10.10.2)\Zn?" 10 65 0 \
       "Sim" "Sim" ON \
       "Não" "Não" OFF)
    if [[ "$adiciona_rota" == "Sim" ]]; then
         echo "# Rota para redirecionamento de IPs privados" >> "$arquivo"
         echo "/ip route" >> "$arquivo"
         echo "add check-gateway=ping disabled=no distance=1 dst-address=$ipprivado/$mascaraprivado gateway=10.10.10.2" >> "$arquivo"
         echo "" >> "$arquivo"
    fi
fi

# Diálogo para perguntar se deseja criar uma address-list para destinos fora do CGNAT
escolha_address_list=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --radiolist "
	\Z2Deseja criar uma address-list com destinos fora do CGNAT?\Zn" 8 65 0 \
    "Sim" "Sim" ON \
    "Não" "Não" OFF)

if [[ $escolha_address_list == "Sim" ]]; then
    nome_lista="FORA-CGNAT"
    nome_lista=$(dialog --colors --stdout --backtitle "$titulo1" --title "$titulo2" --inputbox "\Z2Digite o nome da lista (padrão: FORA-CGNAT):\Zn" 8 60 "$nome_lista")
    if [[ -z "$nome_lista" ]]; then
        nome_lista="FORA-CGNAT"
    fi
    cmd_lista="dst-address-list=!\"$nome_lista\""
    echo "# REGRAS CGNAT" >> "$arquivo"
    echo "/ip firewall nat" >> "$arquivo" 
    echo "add chain=srcnat action=jump jump-target=CGNAT src-address=$ipprivado/$mascaraprivado comment=\"CGNATGEN - Do bloco privado: $ipprivado/$mascaraprivado para o(s) bloco(s) publico(s): $entrada - Desative essa regra para desativar o CGNAT\"" >> "$arquivo" 
    echo "" >> "$arquivo"
else
    cmd_lista=""
    echo "# REGRAS CGNAT" >> "$arquivo"
    echo "/ip firewall nat" >> "$arquivo" 
    echo "add chain=srcnat action=jump jump-target=CGNAT src-address=$ipprivado/$mascaraprivado comment=\"CGNATGEN - Do bloco privado: $ipprivado/$mascaraprivado para o(s) bloco(s) publico(s): $entrada - Desative essa regra para desativar o CGNAT\"" >> "$arquivo" 
    echo "" >> "$arquivo"
fi

# FIM

quantidadepublico=0
for blocopublico in ${entrada[*]}; do
    IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
    quantidadetotalpublico=$(($quantidadetotalpublico+2**$((32-$mascarapublico))))
done

function log2 {
    local l=0
    for (( w=$1-1; w > 0; w >>= 1 )); do
        l=$((l+1))
    done
    echo $l
}

mascaratotalpublico=$((32 - $(log2 $quantidadetotalpublico)))
IFS='.' read -r ipprvpo ipprvso ipprvto ipprvqo <<<"$ipprivado"
for blocopublico in ${entrada[*]}; do
    if which ipcalc >/dev/null; then
        ipcalc -cbn "$blocopublico" | grep -q "Network:" || { 
            dialog --stdout --backtitle "$titulo1" --title "$titulo2" --infobox "Endereço IP ou de rede inválidos" 0 0
            exit
        }
    else
        dialog --stdout --sleep 2 --backtitle "$titulo1" --title "$titulo2" --infobox "ipcalc não está instalado. A validação não foi feita" 0 0
    fi
    IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
    quantidadepublico=$((2**$((32-$mascarapublico))))
    quantidadeprivado=$((2**$((32-$mascaraprivado))))
    relacao=$(($quantidadeprivado/$quantidadetotalpublico))
    portas=$((64000/$relacao))
    if [[ $portas -lt 500 || $portas -gt 8000 ]]; then
        aviso1="AVISO: A quantidade mínima e máxima de portas"
        aviso2="recomendada é 500 e 8000, respectivamente."
    fi
    dialog --colors --cr-wrap --backtitle "$titulo1" --title "$titulo2" --infobox "
                Gerando o arquivo [ \Z1$arquivo\Zn ]
                
                Bloco de IP Público: \Z2$entrada\Zn
                Bloco de IP Pivado: \Z2$ipprivado/$mascaraprivado\Zn
                
                Quantidade de IPs públicos:\Z2 $quantidadetotalpublico\Zn
                Quantidade de IPs privados:\Z2 $quantidadeprivado\Zn
                Relação entre público e privado:\Z2 1:$relacao\Zn
                Quantidade de portas para cada IP privado:\Z2 $portas\Zn
                Quantidade de regras criadas:\Z2 $(( ($quantidadetotalpublico * 2) + ($quantidadeprivado * 2) + 1 ))\Zn
                \Z1$aviso1\Zn
                \Z1$aviso2\Zn
        \Z3Script Desenvolvido por: $autor - Versão: [$versao] OS: $veros\Zn

        \Z2Envie o arquivo para o RouterOS e digite no terminal:\Zn
        \Z1import file=$arquivo\Zn

        \Z4Dica: Use IPv6 no Concentrador\Zn" 22 80
    mascarajump=$((32-($mascaratotalpublico-$mascaraprivado)))
    IFS='.' read -r ippubpo ippubso ippubto ippubqo <<<"$ippublico"
    comecoporta=1501
    y=1
    while [ $y -le $quantidadepublico ]; do
        if [[ $ippubqo -gt 255 ]]; then
            ippubqo=0
            ippubto=$((ippubto + 1))
        fi
        if [[ $ipprvqo -gt 255 ]]; then
            ipprvqo=0
            ipprvto=$((ipprvto + 1))
        fi
        echo "add chain=CGNAT action=jump jump-target=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" src-address=\"$ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump\" comment=\"CGNATGEN - Regra de JUMP do bloco privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo\" $cmd_lista" >> "$arquivo"
        ippubqo=$((ippubqo + 1))
        ipprvqo=$((ipprvqo + $relacao))
        y=$((y + 1))
    done
done

IFS='.' read -r ipprvpo ipprvso ipprvto ipprvqo <<<"$ipprivado"
for blocopublico in ${entrada[*]}; do
    IFS='/' read -r ippublico mascarapublico <<<"$blocopublico"
    IFS='.' read -r ippubpo ippubso ippubto ippubqo <<<"$ippublico"
    y=1
    portainicial=$comecoporta
    while [ $y -le $quantidadepublico ]; do
        if [[ $ippubqo -gt 255 ]]; then
            ippubqo=0
            ippubto=$((ippubto + 1))
        fi
        if [[ $ipprvqo -gt 255 ]]; then
            ipprvqo=0
            ipprvto=$((ipprvto + 1))
        fi
        echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=icmp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump to-address=$ippubpo.$ippubso.$ippubto.$ippubqo comment=\"CGNATGEN - Protocolo: ICMP do bloco privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo/$mascarajump para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo\"" >> "$arquivo"
        x=1
        while [ $x -le $relacao ]; do
            if [[ $ippubqo -gt 255 ]]; then
                ippubqo=0
                ippubto=$((ippubto + 1))
            fi
            if [[ $ipprvqo -gt 255 ]]; then
                ipprvqo=0
                ipprvto=$((ipprvto + 1))
            fi
            portafinal=$((portainicial + portas - 1))
            echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=tcp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo to-address=$ippubpo.$ippubso.$ippubto.$ippubqo to-ports=$portainicial-$portafinal comment=\"CGNATGEN - Protocolo: TCP do IP Privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo, portas de $portainicial a $portafinal\"" >> "$arquivo"
            echo "add chain=\"CGNAT-$ippubpo.$ippubso.$ippubto.$ippubqo\" action=src-nat protocol=udp src-address=$ipprvpo.$ipprvso.$ipprvto.$ipprvqo to-address=$ippubpo.$ippubso.$ippubto.$ippubqo to-ports=$portainicial-$portafinal comment=\"CGNATGEN - Protocolo: UDP do IP Privado: $ipprvpo.$ipprvso.$ipprvto.$ipprvqo para o IP publico: $ippubpo.$ippubso.$ippubto.$ippubqo, portas de $portainicial a $portainicial-$portafinal\"" >> "$arquivo"
            portainicial=$((portainicial + portas))
            ipprvqo=$((ipprvqo + 1))
            x=$((x + 1))
        done
        portainicial=1501
        ippubqo=$((ippubqo + 1))
        y=$((y + 1))
    done
done

# Informativo no LOG
echo "" >> "$arquivo"
echo "# Alertas no LOG do RouterOS" >> "$arquivo"
echo ":log error message=\">> Arquivo ($arquivo) importado com sucesso.\"" >> "$arquivo"
echo ":log error message=\">> CGNATGen - Gerador de Script CGNAT para $veros.\"" >> "$arquivo"
if [[ "$escolha_ip_enlace" == "Sim" && -n "$nome_int_enlace" ]]; then
    echo ":log warning message=\">> IP 10.10.10.1/30 adicionado na interface: $nome_int_enlace\"" >> "$arquivo"
    echo ":log warning message=\">> Configure o IP 10.10.10.2/30 na interface de uplink do seu concentrador.\"" >> "$arquivo"
fi

# Inserindo o cabeçalho no início do arquivo gerado
cabecalho="# Gerando o arquivo [ $arquivo ]
#
# Bloco de IP Público: $entrada
# Bloco de IP Pivado: $ipprivado/$mascaraprivado
# Quantidade de IPs públicos: $quantidadetotalpublico
# Quantidade de IPs privados: $quantidadeprivado
#
# Relação entre público e privado: 1:$relacao
#
# Quantidade de portas para cada IP privado: $portas
# Quantidade de regras criadas: $(( ($quantidadetotalpublico * 2) + ($quantidadeprivado * 2) + 1 ))
#
# Script Desenvolvido por: $autor - Versão: [$versao] OS: $veros
#
# Envie o arquivo para o RouterOS e digite no terminal:
# import file=$arquivo
#
# Dica: Use IPv6 no Concentrador

"
echo "$cabecalho" | cat - "$arquivo" > temp && mv temp "$arquivo"

exit
else
    echo "Dialog não instalado"
fi
