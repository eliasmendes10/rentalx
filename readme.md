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
