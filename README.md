# cgnatgen
Gerador de Script de CGNAT em SRC-NAT para RouterOS baseado na Wiki original da Mikrotik (Não usa NETMAP)
https://help.mikrotik.com/docs/display/ROS/NAT
---------------------------------------------

A ferramenta foi adaptada para uma necessidade pessoal, disponibilizando e flexibilizando a inserção de novas funções dentro do script, tais como:

- Ativar FastTrack
- Ativar o NoTrack (Raw)
- Ativar uma Address-List para não sair pelos IPs do CGNAT (Usar rota padrão)
- Regra de Mascaramento ignorando o range de IPs do CGNAT.
- Adicionado a opção de configurar um ip de enlace entre o CGNAT/Concentrador (10.10.10.1/30)

O arquivo gerado deverá ser enviado e importado para o RouterOS.

Requisitos:
---------------------------------------------

- Testado no Debian 10/11;
- Necessário os pacotes dialog e ipcalc
- 
  Obs: O próprio script verifica se os pacotes estão instalados e força a instalação das dependências.

Imagens:
---------------------------------------------

![image](https://github.com/lerc07/cgnatgen/assets/151892038/d040d3be-9629-4b00-bc98-b84c430f14f3)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/f9c09980-edab-42e0-a3d7-d25842bad82f)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/070d0886-3ebd-4e2e-b4f7-393c6ccec093)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/028ea525-fed2-4e01-80d3-05a7f8bed57e)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/ec3d181c-851d-4965-9495-5a2479c7960e)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/573d1104-5def-4450-8d17-29d2741b3e49)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/a3b19a36-ca11-49ed-808e-c3836c07abd6)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/22d4828a-7f5d-4539-b083-1f6f08967325)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/4f72bc9a-fcec-4843-8e20-5b407375b052)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/ae231b16-cbe0-4a53-9198-7f633b63e2cb)
![image](https://github.com/lerc07/cgnatgen/assets/151892038/fdac13f2-6528-49dc-8530-7a3e9ffe5f74)

Após a importação completa do Script.

![image](https://github.com/lerc07/cgnatgen/assets/151892038/3c1c620c-5388-42ca-a3cc-cf19239fd178)

Realizado algumas modificações das Dialogs para melhor visualisar na shell.

Lembrando que o arquivo gerado deve ser enviado para o RouterOS e importado usando:

/import file=arquivo.rsc

---------------------------------------------

Agradecimento especial ao Autor: Daniel Hoisel, por ter disponibilizado a ferramenta para uso. 

Projeto instpirado em: https://github.com/dvhoisel/cgnatgen 
