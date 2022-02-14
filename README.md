Instalação / configuração do Postgresql

yarn add typeorm
yarn add reflect-metadata
yarn add pg

quando instalar algo como o banco de dados é bom forçar a recriação do container
docker-compose up --force-recreate

Esse comando verifica qual é o ip do nosso container
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' eliasMyStudy
ou
docker exec eliasMyStudy cat /etc/hosts

TypeOrm

Create migration
yarn typeorm migration:create -n CreateCategories
Rodar migration
yarn typeorm migration:run
Reverter Migration
yarn typeorm migration:revert

Ferramenta para Injeção de Dependencia. (TSyringe)
yarn add tsyringe

#TESTES - jest

yarn add jest -D
yarn add @types/jest -D

#para criar jest.config.ts
yarn jest --init

add preset
yarn add ts-jest -D
no config jest adicionar/alterar a propriedade --> preset: "ts-jest"
Depois é necessário configurar o mapeamento das classes que desejamos efetuar testes

Recomendado deixar as pastas dos testes dentro da estrutura "modules > useCase"
Assim fica mais fácil de saber onde está cada teste e o que ele vai fazer

bail: true --> default inicia com false
indica para o jest se a gente quer ou não que o switch de teste pare ao encontrar um erro

#yarn add tsconfig-paths -D
Para configurar o ts config para permitir shortUrl como: @shared, @modules, @errors

# Cadastro de Carro

**RF** => Requisitos Funcionais
Deve ser possível cadastrar um novo carro.
Deve ser possível listar todas as categorias.

**RNF** => Requisitos Não Funcionais

**RN** => Regras de Negócio
Não deve ser possível cadastrar um carro com uma placa já existente.
O carro deve ser cadastrado, por padrão, com disponibilidade.
O usuário responsável pelo cadastro deve ser um usuário administrador.

# Listagem de carros

**RF**
Deve ser possível listar todos os carros disponíveis.
Deve ser possível listar todos os carros disponíveis pelo nome da categoria.
deve ser possível listar todos os carros disponíveis pelo nome da marca.
deve ser possível listar todos os carros disponíveis pelo nome do carro.

**RN**
O usuário não precisa estar logado no sistema.

# Cadastro de Especificação no carro

**RF**
Deve ser possível cadastrar uma especificação para um carro.

**RN**
Não deve ser possível cadastrar uma especificação para um carro não cadastrado.
Não deve ser possível cadastrar uma especificação já existente para o mesmo carro.
O usuário responsável pelo cadastro deve ser um usuário administrador.

# Cadastro de imagens do carro

**RF**
Deve ser possível cadastrar a imagem do carro.
Deve ser possível listar todos os carros.

**RNF**
Utilizar o multar para upload dos arquivos.

**RN**
O usuário deve poder cadastrar mais de uma imagem para o mesmo carro.
O usuário responsável pelo cadastro deve ser um usuário administrador.

# Alugel de carro

**RF**
Deve ser possível cadastrar um aluguel.

**RN**
O aluguel deve ter duração mínima de 24 horas.
Não deve ser possível cadastrar um novo aluguel caso já exista um aberto para o mesmo usuário.
Não deve ser possível cadastrar um novo aluguel caso já exista um aberto para o mesmo carro.
