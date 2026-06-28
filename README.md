# Sistema Jurídico

![img_inicio](https://www.bcompany.com.br/wp-content/uploads/2020/03/martelo-juiz-laptop-sistema-juridico-1024x683.jpg.webp)


O objetivo principal deste trabalho é o desenvolvimento de um modelo de banco de dados relacional projetado para um sistema jurídico, bem como uma API Relacional para utilizá-lo. A proposta visa criar um repositório centralizado para organizar informações e documentos da área do Direito, simplificando e otimizando o acesso por parte dos profissionais da área.

O sistema gerencia:
* Processos judiciais
* Os atores envolvidos, como autores, réus, juízes e advogados
* Trâmites processuais e os documentos gerados
* A estrutura organizacional do sistema judiciário, como Comarcas e Varas

## Modelagem do banco de dados

### 1. Escopo e Entidades Centrais

O modelo foi estruturado em quatro núcleos de informação principais para abranger as áreas fundamentais da gestão de um processo judicial:

* **Núcleo do Processo:** Representado pelas entidades `Processo` e `Tramite`. O trâmite possui especializações como `Audiencia` e `Decisao` para detalhar eventos específicos.
* **Atores e Participantes:** Utiliza a entidade `Pessoa` como uma generalização que se especializa em papéis como `Advogado` e `Agente Judiciário`, que por sua vez se divide em `Juiz` e `Servidor Público`.
* **Estrutura Organizacional:** As entidades `Comarca` e `Vara` definem a hierarquia e a localização jurisdicional onde os processos tramitam. 
* Fundamentação e Conteúdo:** As entidades `Documento` e `Lei` representam os artefatos que fornecem suporte e conteúdo aos eventos do processo. 

### 2. Regras de Negócio

O sistema é governado por um conjunto de regras de negócio que definem a integridade e a lógica das relações entre as entidades. As principais regras são:

* **Hierarquia e Lotação:**
    * Um `Juiz` deve estar lotado em uma única `Vara`. 
    * Um `Servidor Público` está lotado em uma única `Comarca`. 
    * Uma `Vara` deve pertencer a uma e somente uma `Comarca`. 

* **Estrutura Processual:**
    * Um `Processo` tramita em uma única `Vara` e é de responsabilidade de um único `Juiz`. 
    * Todo `Processo` deve possuir ao menos um `Tramite` associado. 
    * Um `Tramite` pode gerar um ou mais `Documentos`, mas um `Documento` pertence a um único `Tramite`. 

* **Participação das Partes:**
    * A relação entre `Pessoa` e `Processo` é de muitos-para-muitos, formalizada pela entidade associativa `Parte`. 
    * A defesa de uma `Pessoa` (parte) em um `Processo` por um `Advogado` é representada por um relacionamento ternário. 

### 3. Esquema Conceitual (EER)

![img_EER](https://github.com/hertonnn/Sistema-Juridico/blob/main/refs/Parte%201%20-%20Corrigida/Conceitual_1.png?raw=true)

O projeto inclui um Esquema Entidade-Relacionamento Estendido (EER) que ilustra visualmente as entidades, seus atributos e os relacionamentos definidos pelas regras de negócio. 

O diagrama detalha as cardinalidades e a estrutura geral do banco de dados, servindo como um guia para a implementação física.

### 4. Dicionário de Dados

Um dicionário de dados detalhado foi elaborado para documentar todas as entidades e seus respectivos atributos.  Para cada atributo, são especificados o tipo de dado, restrições (chaves primárias, estrangeiras, etc.) e sua descrição. 

## API Relacional

![api](https://github.com/hertonnn/Sistema-Juridico/blob/main/refs/Parte%201%20-%20Corrigida/c%C3%B3digo.png?raw=true)

O Padrão de arquitetura usado foi o MVC (Model-View-Controller). O MVC é um padrão que visa separar uma aplicação em três componentes interligados, cada um com uma responsabilidade específica. Isso organiza o código, facilita a manutenção e permite que diferentes equipes (ex: backend e frontend) trabalhem em paralelo. Grande parte do código do padrão foi disponibilizado pela professora para reutilizarmos em nosso contexto.

Para a criação da API foram requisitados apenas no máximo 5 tabelas do banco de dados relacionadas. Com o banco de dados(disponibilizado nos arquivos) criado, execute apenas o comando para rodar caso não tenha feito modificações prévias no projeto.

- Compila 

	javac -d out src/*.java src/bean/*.java src/controller/*.java src/db/*.java src/model/*.java

- Empacota os .class em .jar

	jar cfm Run.jar MANIFEST.MF -C out .

- Roda
	
	java -jar Run.jar


## Considerações finais

Em sumo, esse trabalho de conclusão final da disciplina de BAN1 foi crucial para relembrar e sintetizar todo conteúdo teórico e prático visto no decorrer do semestre.

**Disciplina:** Banco de Dados I  

**Instituição:** Universidade do Estado de Santa Catarina (UDESC) - Centro de Ciências Tecnológicas (CCT)   

**Autores:** Adriano Silva, Herton Silveira   

**Professora**: Dra. Rebeca Schroeder Freitas 

**Ano:** 2025 



