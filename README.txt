===================================================
                 OpenSaturn Kernel
===================================================

OpenSaturn é um kernel de sistema operacional Unix-based,
escrito inteiramente em Zig, projetado com os princípios de
simplicidade, modularidade e personalização total.

É uma iniciativa pensada para desenvolvedores que desejam
compreender, estender e moldar cada camada do seu sistema
operacional, desde as syscalls até os drivers e o sistema
de arquivos.

---------------------------------------------------
                 Por que Zig?
---------------------------------------------------

O Zig foi escolhido como a linguagem principal do
OpenSaturn por vários motivos técnicos:

  - O controle de baixo nível superou até mesmo o de C
    (na minha opinião);

  - O controle sobre o código assembly gerado é incrível.
    Saber exatamente como o assembly do código vai sair
    é uma das melhores vantagens de usar uma linguagem
    como Zig;

  - Totalmente compatível com C, ou seja, programadores
    que quiserem contribuir com drivers não precisam
    aprender Zig. No futuro, pretendo disponibilizar
    headers para criação de módulos em C.

  - Metaprogramação incrível

---------------------------------------------------
           Filosofia do OpenSaturn (KISS)
---------------------------------------------------

OpenSaturn segue a filosofia KISS (Keep It Simple, Stupid):

  - Código simples, direto e sem complexidade desnecessária;
  - Fácil leitura, entendimento e modificação.

Em vez de tentar ser um kernel com milhões de recursos
embutidos, o OpenSaturn se concentra em fornecer uma base
sólida, segura e extensível — ideal para quem deseja
construir algo próprio em cima.

---------------------------------------------------
              Criação de Recursos
---------------------------------------------------

OpenSaturn é especialmente projetado para facilitar a
criação e integração de:

  - Drivers personalizados;
  - Sistemas de arquivos;
  - Syscalls customizadas.

Acredito que o programador deve se preocupar apenas com
a complexidade do seu próprio código, sem precisar lidar
com a complexidade de como integrá-lo ao kernel.

---------------------------------------------------
              Objetivos do Projeto
---------------------------------------------------

  - Ser uma base educacional para entusiastas de sistemas
    operacionais;

  - Permitir controle completo sobre todos os aspectos
    do kernel;

  - Facilitar a portabilidade do kernel para diferentes
    tipos de dispositivos.

---------------------------------------------------
               Status do Projeto
---------------------------------------------------

O kernel está em desenvolvimento ativo, com foco inicial
nos seguintes componentes:

  - Sistema de módulos para drivers, dispositivos, sistemas
    de arquivos e syscalls;

  - Gerenciamento de memória, paging e alocações básicas
    para o próprio kernel e seus módulos.

===================================================

