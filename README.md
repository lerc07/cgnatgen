# cgnatgen
Gerador de Script de CGNAT em SRC-NAT para RouterOS baseado na Wiki original da Mikrotik (Não usa NETMAP)
https://help.mikrotik.com/docs/display/ROS/NAT
---------------------------------------------

A ferramenta foi adaptada para uma necessidade pessoal, diferenciando a versão do RouterOS e disponibilizando a inserção de novas funções dentro do script, tais como:

- Ativar FastTrack (Com explicações);
- Ativar o NoTrack (Raw) (Com expicações);
- Ativar uma Address-List para não sair pelos IPs do CGNAT (Usar rota padrão);
- Ativar regras no Blackhole para não precisar fazer várias Loopbacks;
- Regra de Mascaramento ignorando o range de IPs do CGNAT.
- Adicionado a opção de configurar um ip de enlace entre o CGNAT/Concentrador (10.10.10.1/30)

O arquivo gerado deverá ser enviado e importado para o RouterOS.

Requisitos:
---------------------------------------------

- Testado no Debian 10/11/12 e Ubuntu;
- Necessário os pacotes dialog e ipcalc 
- Ao executar o script como sudo/root, a ferramenta instala os requisitos automaticamente.

  Obs: O próprio script verifica se os pacotes estão instalados e força a instalação das dependências.

Imagens:
---------------------------------------------

![01](https://github.com/user-attachments/assets/0538bafd-e893-4645-be2b-56fafc471e5f)
![02](https://github.com/user-attachments/assets/b15e40bd-ae5f-4954-9cfc-60a3c0591dbb)
![03](https://github.com/user-attachments/assets/3da56679-2475-4328-8dac-c93b6bfeda1a)
![04](https://github.com/user-attachments/assets/e3c5c8d0-143d-4d4a-bc2c-acfc456ef9d9)
![05](https://github.com/user-attachments/assets/f92dcb56-d4b0-48e5-90c3-3255fa7a3105)
![06](https://github.com/user-attachments/assets/58b22906-9cd5-461a-820f-c1c2e320218a)
![07](https://github.com/user-attachments/assets/372ccf3e-e484-4404-9375-fdb928214ad1)
![08](https://github.com/user-attachments/assets/bbe70674-5b5f-423d-90d3-2438315397d7)
![09](https://github.com/user-attachments/assets/fe0ce165-a5fc-4b8d-a2b3-c8e0762b91cf)
![10](https://github.com/user-attachments/assets/2cdb806c-44d2-4c04-872b-1282eb887381)
![11](https://github.com/user-attachments/assets/91bc51d8-8fc4-4401-aa15-360c35566b6e)
![12](https://github.com/user-attachments/assets/99c97ab1-b782-42de-a9f2-0a484dcaaa07)
![13](https://github.com/user-attachments/assets/6d90268d-74b3-4490-b301-50e738468131)
![14](https://github.com/user-attachments/assets/6c4b573a-e688-45a8-b0db-8e494e7c9ece)
![15](https://github.com/user-attachments/assets/1b67bb29-235e-41de-bb19-3fd1d9fead80)

Após a importação completa do Script.

![image](https://github.com/lerc07/cgnatgen/assets/151892038/3c1c620c-5388-42ca-a3cc-cf19239fd178)

Realizado algumas modificações das Dialogs para melhor visualisar na shell.

Lembrando que o arquivo gerado deve ser enviado para o RouterOS e importado usando:

/import file=arquivo.rsc

---------------------------------------------

Agradecimento especial ao Autor: Daniel Hoisel, por ter disponibilizado a ferramenta para uso. 

Projeto instpirado em: https://github.com/dvhoisel/cgnatgen 
