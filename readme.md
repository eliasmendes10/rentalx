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
