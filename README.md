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

![01](https://github.com/user-attachments/assets/3e02bd67-1848-4b34-923f-011412628a30)
![02](https://github.com/user-attachments/assets/4536a744-89bb-4b5b-b597-46ce058ad2b4)
![03](https://github.com/user-attachments/assets/831250bd-7ad5-4719-968a-417be261a49c)
![04](https://github.com/user-attachments/assets/54ff59cd-47ce-433d-89f4-ee706291ef6c)
![05](https://github.com/user-attachments/assets/1291206a-a3ad-4518-bece-4e76f72b7949)
![06](https://github.com/user-attachments/assets/dfbd5944-7162-4828-8016-ab0c812e5624)
![07](https://github.com/user-attachments/assets/7bd4c2c1-29ef-4d25-97aa-de0666ca1f12)
![08](https://github.com/user-attachments/assets/aba9d5ed-b112-411c-94e1-02848cc3f578)
![09](https://github.com/user-attachments/assets/9eead5be-e517-4958-bfd5-2fed14800953)
![10](https://github.com/user-attachments/assets/05c10359-c6e9-41e0-a9d6-376d95a7d292)
![11](https://github.com/user-attachments/assets/eac1a80f-b475-4d5a-b3c0-d3ad21fce407)
![12](https://github.com/user-attachments/assets/3ed21269-604f-4fc8-b4a1-292b33ce0942)
![13](https://github.com/user-attachments/assets/4565a575-5307-47ff-8081-cdb2d2ba12da)
![14](https://github.com/user-attachments/assets/c3f289f3-03e3-4c85-b22c-6d838d26c0a7)

Após a importação completa do Script.

![image](https://github.com/lerc07/cgnatgen/assets/151892038/3c1c620c-5388-42ca-a3cc-cf19239fd178)

Realizado algumas modificações das Dialogs para melhor visualisar na shell.

Lembrando que o arquivo gerado deve ser enviado para o RouterOS e importado usando:

/import file=arquivo.rsc

---------------------------------------------

Agradecimento especial ao Autor: Daniel Hoisel, por ter disponibilizado a ferramenta para uso. 

Projeto instpirado em: https://github.com/dvhoisel/cgnatgen 
