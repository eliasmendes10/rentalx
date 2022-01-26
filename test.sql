-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[upn_GetProductsAndPromotions010] 
	@CompanyCode					Varchar(002)	= '',				-- CÓDIGO DA EMPRESA
	@BranchCode						Varchar(006)	= '', 				-- CÓDIGO DA FILIAL 
	@CustomerCode					Varchar(011)	= '', 				-- CÓDIGO DO CLIENTE
	@CustomerStore					Varchar(004)	= '', 				-- LOJA DO CLIENTE
	@SearchFilter					Varchar(Max)	= '', 				-- USADO NO FILTRO DA QUERY PARA BUSCAR POR STRING NO CASO QUANDO FOR POR SEARCH
	@SearchFields					Varchar(Max)	= '', 				-- USADO PARA INDICAR QUAIS CAMPOS QUER FILTRAR SEPARADOS POR PIPE (|)
    @ProductCode					Varchar(Max)	= '', 				-- SEPARAR MAIS DE UM CODIGO POR PIPE (|)
	@BrandCode						Varchar(Max)	= '', 				-- CÓDIGO DAS PROMOÇÕES SEPARADOS POR PIPE (|);
	@CategoryCode					Varchar(Max)	= '', 				-- CÓDIGO DAS PROMOÇÕES SEPARADOS POR PIPE (|);
	@PromotionCode					Varchar(Max)	= '', 				-- CÓDIGO DAS PROMOÇÕES SEPARADOS POR PIPE (|);
	@PromotionItem					Varchar(004)	= '', 				-- CÓDIGO DAS PROMOÇÕES SEPARADOS POR PIPE (|);
	@UserCode						Varchar(Max)	= '', 				-- CÓDIGO DOS USUÁRIOS SEPARADOS POR PIPE (|);
	@PaymentConditionCode			Varchar(Max)	= '', 				-- CÓDIGO DOS USUÁRIOS SEPARADOS POR PIPE (|);
	@PlaceUse						Varchar(Max)	= 'P', 				-- SEPARADOR DE MAIS OPÇÕES PIPE (|)
	@SalesOrderCode					Varchar(040)	= '',				-- ID do carrinho que vai ser filtrado quando informado
	@PageNumber						Int				= 1,				-- NÚMERO DA PAGINA A SER EXIBIDA
	@NumberRowsPerPage				Int				= 2147483647, 		-- NUMERO DE LINHAS POR PAGINAS				
	@QueryResult					Varchar(010)	= 'ALL', 			-- DIZ O QUE A QUERY DEVE RESULTAR ALL=TUDO PROMOÇÃO E VENDA NORMAL, PRODUCT=SOMENTE A QUERY DE PRODUTOS SEM AS PROMOÇÕES, PROMOTION= Somente as promoções, HOME, MAIN OU SHOWCASE= Volta os dados para a montar os top, uma vitrine
	@OrderByQuery					Varchar(050)	= 'BESTSELLERS DESC', 
	@OrderByFilters					Varchar(050)	= 'COUNT DESC',		-- ORDERNA OS FILTROS QUE VAO APARECER AO LADO ESQUERDO DAS TELAS DE LISTA DE PRODUTOS
	@SelectTopItensBestSellers		Int				= 50, 				-- NUMERO DE ITENS QUE O TOP NO SELECT VAI MOSTRAR DE MAIS VENDIDOS.								  
	@SelectTopItensLatestPurchases	Int				= 50, 				-- NUMERO DE ITENS QUE O TOP NO SELECT VAI MOSTRAR DE PRODUTOS.									  
	@SelectTopItensNewProducts		Int				= 50, 				-- NUMERO DE ITENS QUE O TOP NO SELECT VAI MOSTRAR DE PRODUTOS NOVOS.								  
	@SelectTopItensKFGProducts		Int				= 50, 				-- NUMERO DE ITENS QUE O TOP NO SELECT VAI MOSTRAR DE PRODUTOS NOVOS.								  
	@SelectTopItensPromotions		Int				= 50, 				-- NUMERO DE ITENS QUE O TOP NO SELECT VAI MOSTRAR DE PROMOÇÕES.								  
	@SelectTopItensPromotionsBanner	Int				= 06, 				-- NUMERO DE BANNER DE PROMOÇÕES QUE VAI APARECER
	@ValidateProductBlocking		Varchar(001)	= 'N',				-- INDICA SE VAI OU NAO EXECUTAR O RETORNO DE BLOQUEIO DE MERCADORIAS
	@ConcatRouteImage				Varchar(001)	= 'S',				-- INDICA SE DEVE OU NÃO CONCATENAR NO INICIO DA ROTA DAS IMAGENS O FOLDER IMAGES
	@Orign				            Varchar(015)	= '   ',
	@IncludeTYPEIN            		Varchar(001)    = 'N',              -- INDICA SE DEVE DESATIVAR O FILTRO DO APP_TYPEIN
	@IncludeGRPNOT            		Varchar(001)    = 'N',              -- INDICA SE DEVE DESATIVAR O FILTRO DO APP_GRPNOT
	@IncludeGPNOEX            		Varchar(001)    = 'N',              -- INDICA SE DEVE DESATIVAR O FILTRO DO APP_GPNOEX
	@resultPromotion				Varchar(001)	= 'N'
AS
BEGIN	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- +-------------------------------------------------------------------------------------------------------------+
	-- | Validações para ver se as variaveis que foram passadas por parâmetros estão corretas e no padrão necessário |
	-- +-------------------------------------------------------------------------------------------------------------+
	IF @CompanyCode is null or @CompanyCode = '' or @BranchCode is null or @BranchCode = '' 
	BEGIN;
		RAISERROR('The @company and @branch variable cannot be empty!', 16, 1);
		RETURN;
	END;
	
	-- +----------------------------------------+
	-- | Valida se os dados do clientes está ok |
	-- +----------------------------------------+
	IF @CustomerCode is null or @CustomerCode = '' or @CustomerStore is null or @CustomerStore = '' 
	BEGIN;
		RAISERROR('The @customer_code and @customer_store variable cannot be empty!', 16, 1);
		RETURN;
	END;
	
	-- +--------------------------------------------------------------+
	-- | Se informou o @SearchFilter não pode informar o @ProductCode |
	-- +--------------------------------------------------------------+
	IF @SearchFilter != '' AND @ProductCode != ''
	BEGIN;
		RAISERROR('As variáveis @ProductCode e @SearchFilter não pode ser utilizada juntas, caso informe o @SearchFilter não pode informar a @ProductCode e vice-versa!', 16, 1);
		RETURN;
	END;

	-- +---------------------------------------------------------------------------+
	-- | Se informar o @PromotionItem o @PromotionCode tem que ser um código exato |
	-- +---------------------------------------------------------------------------+
	IF @PromotionItem != '' AND (@PromotionCode is null OR @PromotionCode = '' OR @PromotionCode LIKE '%|%')
	BEGIN;
		RAISERROR('Quando a variável @PromotionItem é informada a variável @PromotionCode tem que conter o código da promoção e somente um único código pode ser informado na variável @PromotionCode!', 16, 1);
		RETURN;
	END;

	-- +-------------------------------+
	-- | Valida qual o dado de retorno |
	-- +-------------------------------+
	IF @QueryResult IS NULL OR @QueryResult = '' OR rTrim(Upper(@QueryResult)) NOT IN ('ALL', 'ORDER', 'HOME', 'MAIN', 'SHOWCASE', 'PRODUCT', 'PROMOTION')
	BEGIN;
		RAISERROR('A variável @QueryResult tem que ser informada com ALL, ORDER, HOME, MAIN, SHOWCASE, PRODUCT ou PROMOTION!', 16, 1);
		RETURN;
	END;

	-- +----------------------------+
	-- | Valida o order by da query |
	-- +----------------------------+
	IF @OrderByQuery != '' AND @OrderByQuery NOT IN ('CODE', 'CODE ASC', 'CODE DESC', 'DESCRIPTION', 'DESCRIPTION ASC', 'DESCRIPTION DESC', 'PRICE', 'PRICE ASC', 'PRICE DESC', 'BESTSELLERS', 'BESTSELLERS ASC', 'BESTSELLERS DESC', 'LAUNCHES', 'LAUNCHES ASC', 'LAUNCHES DESC', 'PURCHASES', 'PURCHASES ASC', 'PURCHASES DESC', 'PRODUCT_CODE_ORDER', 'PRODUCT_CODE_ORDER DESC', 'MIN_PRICE', 'MIN_PRICE ASC', 'MIN_PRICE DESC', 'SUG_PRICE', 'SUG_PRICE ASC', 'SUG_PRICE DESC', 'STOCK', 'STOCK ASC', 'STOCK DESC')
	BEGIN;
		RAISERROR('A variável @OrderByQuery tem que ser informada com CODE, CODE ASC, CODE DESC, DESCRIPTION, DESCRIPTION ASC, DESCRIPTION DESC, PRICE, PRICE ASC, PRICE DESC, LAUNCHES, LAUNCHES ASC, LAUNCHES DESC, PURCHASES, PURCHASES ASC e PURCHASES DESC, PRODUCT_CODE_ORDER, PRODUCT_CODE_ORDER DESC!', 16, 1);
		RETURN;
	END;
	
	-- +----------------------------------------+
	-- | Valida o order by dos filtros laterais |
	-- +----------------------------------------+
	IF @OrderByFilters != '' AND @OrderByFilters NOT IN ('CODE', 'CODE ASC', 'CODE DESC', 'NAME', 'NAME ASC', 'NAME DESC', 'COUNT', 'COUNT ASC', 'COUNT DESC')
	BEGIN;
		RAISERROR('A variável @OrderByFilters tem que ser informada com CODE, CODE ASC, CODE DESC, NAME, NAME ASC, NAME DESC, COUNT, COUNT ASC e COUNT DESC!', 16, 1);
		RETURN;
	END;

	-- +----------------------------------+
	-- | Valida se foi informado a @Orign |
	-- +----------------------------------+
	IF @Orign IS NULL OR @Orign = '' 
	BEGIN;
		RAISERROR('A variável @Orign não pode ser vazia!', 16, 1);
		RETURN;
	END;

	-- +---------------------------------------+
	-- | Valida se o valor de @Orign é correto |
	-- +---------------------------------------+
	IF @Orign NOT IN ('KFGPORCLI', 'KFGPEDVEN') 
	BEGIN;
		RAISERROR('A variável @Orign tem que ser informada como KFGPORCLI e KFGPEDVEN!', 16, 1);
		RETURN;
	END;

	-- +-----------------------------------------------------------------+
	-- | CRIA ALGUMAS VARIAVEIS QUE VAÃO SER USADAS NO DECORRER DA QUERY |
	-- +-----------------------------------------------------------------+
	Declare @ProductQueryExecute		TinyInt			= IIF( (rTrim(@QueryResult) = '' OR @QueryResult IS NULL OR rTrim(Upper(@QueryResult)) IN ('ALL', 'PRODUCT', 'ORDER'))	, 1, 0)	 -- DEFINE SE DEVE EXIBIR O RESULTADO DE BUSCA DE PRODUTOS, 1 SIM DOIS NAO
	Declare @PromotionQueryExecute		TinyInt			= IIF( (rTrim(@QueryResult) = '' OR @QueryResult IS NULL OR rTrim(Upper(@QueryResult)) IN ('ALL', 'PROMOTION', 'ORDER')) , 1, 0) -- DEFINE SE DEVE EXIBIR O RESULTADO DE BUSCA DE PROMOÇÃO, 1 SIM DOIS NAO
	Declare @MainQueryExecute			TinyInt			= IIF( (rTrim(@QueryResult) = '' OR @QueryResult IS NULL OR rTrim(Upper(@QueryResult)) IN ('HOME', 'MAIN', 'SHOWCASE')) , 1, 0)  -- DEFINE SE DEVE EXIBIR O RESULTADO DE BUSCA DOS TOPS DA VITRINE, 1 SIM DOIS NAO
	
	Declare @ProductRowResult			Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE BUSCA O PREÇO DA TABELA DE PREÇO DO CLIENTE OU SE ELE TIVER ULTIMAS COMRPRAS
	Declare @PromotionRowResult			Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY AS PROMOÇÕES QUE O CLIENTE SE ENQUANDRA
	Declare @BestsellersRowResult		Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS MAIS VENDIDOS
	Declare @LastPruchaseRowResult		Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS MAIS VENDIDOS
	Declare @NewProductsRowResult		Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS NOVOS
	
	Declare @KFGProductsRowResult		Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	Declare @KFGAdaRowResult			Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	Declare @KFGVillaRicaRowResult		Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	Declare @KFGMariaBonitaRowResult	Int				= 0				-- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	Declare @KFGOrganicumRowResult      Int             = 0             -- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	Declare @KFGCoffeonRowResult        Int             = 0             -- CONTADOR DE TOTAL DE LINHAS DA QUERY QUE VAI MOSTRAR OS PRODUTOS DA KFG
	
	Declare @BrandListObject			Varchar(Max)	= '[]'			-- RETORNA UM JSON COM TODAS AS MARCAS QUE VOLTARAM NA BUSCA
	Declare @CategoryListObject			Varchar(Max)	= '[]'			-- RETORNA UM JSON COM TODAS AS CATEGORIAS OU COMO CONHECIDO NO PROTHEUS GRUPO DE PRODUTOS QUE VOLTARAM NA BUSCA
	Declare @PromotionListObject		Varchar(Max)	= '[]'			-- RETORNA UM JSON COM TODAS AS DESCRIÇÕES DE PROMOÇÕES QUE VOLTARAM NA BUSCA
	Declare @CutOffDateLatestPurchases	Varchar(008)	= '20150101'	-- Data de corte das ultimas compras caso queira limitar um perido para ser usado nas ultimas compras

	 -- +--------------------+
	-- | TRATA AS VARIAVEIS |
	-- +--------------------+
	SET @SearchFilter = dbo.ufn_getAdjustedLike(@SearchFilter);

	IF (Trim(@SearchFields) = '')
	BEGIN;
		SET @SearchFields = 'B1_COD|B1_PROC|B1_DESC|B1_ZCODBAR|B1_CODBAR|B5_CEME|B5_ZPOSOL|B5_ZINDIPR|BM_DESC|Z00_MARCA';
	END;
	
	-- +---------------------------------------------------------------------------------------+
	-- | Validação e controle de paginação para ver se ficou de acordo com o padrão necessário |
	-- +---------------------------------------------------------------------------------------+
	IF @PageNumber <= 0 OR @NumberRowsPerPage <= 0 OR @PageNumber IS NULL OR @NumberRowsPerPage IS NULL 
	BEGIN;
		SET @PageNumber		= 1;
		SET @NumberRowsPerPage	= 2147483647;
	END;

	-- +--------------------+
	-- | Arruma a paginação |
	-- +--------------------+
	SET @PageNumber = (@PageNumber - 1) * @NumberRowsPerPage;

	-- +--------------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DOS MAIS VENDIDOS SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +--------------------------------------------------------------------------------------+
	IF @SelectTopItensBestSellers IS NULL OR @SelectTopItensBestSellers <= 0 SET @SelectTopItensBestSellers = 50; 

	-- +---------------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DOS PRODUTOS NOVOS SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +---------------------------------------------------------------------------------------+
	IF @SelectTopItensNewProducts IS NULL OR @SelectTopItensNewProducts <= 0 SET @SelectTopItensNewProducts = 50;

	-- +-------------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DOS PRODUTOS KFG SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +-------------------------------------------------------------------------------------+
	IF @SelectTopItensKFGProducts IS NULL OR @SelectTopItensKFGProducts <= 0  SET @SelectTopItensKFGProducts = 50;

	-- +---------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DOS PRODUTOS SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +---------------------------------------------------------------------------------+
	IF @SelectTopItensLatestPurchases IS NULL OR @SelectTopItensLatestPurchases <= 0 SET @SelectTopItensLatestPurchases = 50;

	-- +----------------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DAS ULTIMAS COMPRAS SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +----------------------------------------------------------------------------------------+
	IF @SelectTopItensPromotions IS NULL OR @SelectTopItensPromotions <= 0 SET @SelectTopItensPromotions = 50; 

	-- +--------------------------------------------------------------------------------------------+
	-- | VALIDA AO TOP DO SELECT DOS BANNER DE PROMOÇÕES SE OS DADOS ESTÃO OK SE NÃO SET UM DEFAULT |
	-- +--------------------------------------------------------------------------------------------+
	IF @SelectTopItensPromotionsBanner IS NULL OR @SelectTopItensPromotionsBanner <= 0 SET @SelectTopItensPromotionsBanner = 06; 
		
	-- +------------------------------------------------------------------------------------------------------+
	-- | CARREGA PARA UMA TABELA TEMPORARIA OS DADOS DE PARÂMETROS PARA PODER BUSCAR PELAS FILIAS DAS TABELAS |
	-- +------------------------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SX2') IS NOT NULL DROP TABLE #TEMP_SX2

	SELECT SX2.TABELA, SX2.XFILIAL
	INTO #TEMP_SX2
	FROM APP_SX2 SX2 WITH (NOLOCK)
	WHERE	SX2.EMPRESA = @CompanyCode
		AND SX2.FILIAL	= @BranchCode 
		AND SX2.TABELA IN (
			'CC2', -- Cadastro de cidades.
			'DA1', -- Itens da tabela de preço.
			'SA1', -- Cadastro de clientes.
			'SA2', -- Cadastro de fornecerdor.
			'SA3', -- Cadastro de representante.
			'SAH', -- Cadastro de unidade de medidas.
			'SB1', -- Cadastro de produtos.
			'SB2', -- Controle de saldos fisico de produtos.
			'SB5', -- Cadastro de complemento de produtos.
			'SD2', -- Itens da nota fiscal de saída.
			'SF4', -- Tipo de entrada e saída - TES.
			'SF7', -- Cadastro de exceções fiscais.
			'SG1', -- Cadastro de extrutura de produtos.
			'SX5', -- Tabelas genéricas.
			'SYD', -- Cadastro de Nomenclatura comum do mercosul - N.C.M.
			'Z00', -- Cadastro de marcas de produtos.
			'ZA5', -- Cadastro de caixa padrão. 
			'ZK1', -- Cabeçalho dos orçamentos de pedidos de vendas
			'ZK2', -- Itens dos orçamento de pedidos de vendas
			'ZZ8', -- Cadastro de setores de vendas.
			'ZZQ', -- Cabeçalho do cadastro das promoções e negociações.
			'ZZR', -- Itens do cadastro das promoções e negociações.
			'ZZS',  -- Exceções do cadastro das promoções e negociações.
			'SC7' 
		)

	-- SELECT * FROM #TEMP_SX2
	
	-- +-----------------------------------------------------------------------+
	-- | VALIDA SE ACHOU TODOS OS XFILIAL DAS TABELAS PARA VER SE ESTÁ TUDO OK |
	-- +-----------------------------------------------------------------------+
	IF (SELECT COUNT(SX2.TABELA) FROM #TEMP_SX2 SX2) != 24
	BEGIN;
		RAISERROR('A Temp #TEMP_SX2 está faltando tabela de controle de filial!', 16, 1);
		RETURN;
	END;

	-- +--------------------------------------------------------------------------------------+
	-- | CARREGA EM UMA TABELA TEMPORARIA TODOS OS PARÂMETROS UTILIZADO NA CONSULTA DOS DADOS |
	-- +--------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SX6') IS NOT NULL DROP TABLE #TEMP_SX6

	SELECT SX6.X6_VAR, SX6.X6_CONTEUD, value AS X6_VALUE -- COMO UTILIZEI A FUNÇÃO STRING_SPLIT PARA QUEBRAR OS PARAMETROS EM LINHAS O MESMO FOI RECUPERADO PELA VARIAVEL VALUE
	INTO #TEMP_SX6
	FROM APP_SX6 SX6 WITH (NOLOCK) CROSS APPLY STRING_SPLIT(SX6.X6_CONTEUD, '/')
	WHERE	SX6.X6_EMPRESA	= @CompanyCode 
		AND SX6.X6_FILIAL	= @BranchCode 
		AND SX6.X6_VAR IN (
			'APP_GRPNOT', -- Grupo de produtos que não podem ser comprados por clientes e nem adicionados a pedidos de vendas, pois saão grupos de uso interno da KFG. Comparado com o campo B1_GRUPO do cadastro de produtos.
			'APP_GPNOEX', -- Grupos de produtos de vão ser adcionado aos pedidos atrávés de negociações ou promoções porém não aparece na busca como produtos para compra como brindes por exemplo. Separa por barra (/). Comparado com o campo B1_GRUPO do cadastro de produtos.
			'APP_TYPEIN', -- Tipos de produtos que poderão que são comercializados pela empresa, ou seja que podem ser vendidos, separar por barra (/). Comparado com o campo B1_TIPO do cadastro de produtos.
			'APP_PZNVPD'  -- Prazo médio em dias para avaliar quando o produto é uma novidade, informar em dias. 0 (ZERO) desativa a exibição de novidades. Comparado com o campo B1_ZPRDNOV do cadastro de produtos.
		)
	
	-- SELECT * FROM #TEMP_SX6
	

	DECLARE @DATE_NOV VARCHAR(8) = FORMAT(DATEADD(DAY, ISNULL((SELECT TOP 1 X6_CONTEUD FROM #TEMP_SX6 WHERE X6_VAR = 'APP_PZNVPD'), 0) * -1, GetDate()), 'yyyyMMdd');	

	-- DECLARA AS VARIAVEIS PARA EVITAR UTILIZAR AS TABELAS TEMPORÁRIAS E GANHAR PERFORMANCE
	DECLARE 
		@FILIAL_SX5 VARCHAR(6), @FILIAL_CC2 VARCHAR(6), @FILIAL_SA3 VARCHAR(6), @FILIAL_ZZ8 VARCHAR(6), @FILIAL_SA1 VARCHAR(6),
		@FILIAL_SF4 VARCHAR(6), @FILIAL_ZK2 VARCHAR(6), @FILIAL_SB1 VARCHAR(6), @FILIAL_SAH VARCHAR(6), @FILIAL_SF7 VARCHAR(6),
		@FILIAL_SB2 VARCHAR(6), @FILIAL_SYD VARCHAR(6), @FILIAL_SC7 VARCHAR(6), @FILIAL_SD2 VARCHAR(6), @FILIAL_Z00 VARCHAR(6), 
		@FILIAL_ZA5 VARCHAR(6), @FILIAL_SB5 VARCHAR(6), @FILIAL_SA2 VARCHAR(6), @FILIAL_DA1 VARCHAR(6), @FILIAL_ZK1 VARCHAR(6), 
		@FILIAL_ZZQ VARCHAR(6)

	SELECT TOP 1 @FILIAL_SX5 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SX5'
	SELECT TOP 1 @FILIAL_CC2 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'CC2'
	SELECT TOP 1 @FILIAL_SA3 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SA3'
	SELECT TOP 1 @FILIAL_ZZ8 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'ZZ8'
	SELECT TOP 1 @FILIAL_SA1 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SA1'
	SELECT TOP 1 @FILIAL_SF4 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SF4'
	SELECT TOP 1 @FILIAL_ZK2 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'ZK2'
	SELECT TOP 1 @FILIAL_SB1 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SB1'
	SELECT TOP 1 @FILIAL_SAH = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SAH'
	SELECT TOP 1 @FILIAL_SF7 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SF7'
	SELECT TOP 1 @FILIAL_SB2 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SB2'
	SELECT TOP 1 @FILIAL_SYD = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SYD'
	SELECT TOP 1 @FILIAL_SC7 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SC7'
	SELECT TOP 1 @FILIAL_SD2 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SD2'
	SELECT TOP 1 @FILIAL_Z00 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'Z00'
	SELECT TOP 1 @FILIAL_ZA5 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'ZA5'
	SELECT TOP 1 @FILIAL_SB5 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SB5'
	SELECT TOP 1 @FILIAL_SA2 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'SA2'
	SELECT TOP 1 @FILIAL_DA1 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'DA1'
	SELECT TOP 1 @FILIAL_ZK1 = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'ZK1'
	SELECT TOP 1 @FILIAL_ZZQ = ISNULL(XFILIAL, '') FROM #TEMP_SX2 WHERE TABELA = 'ZZQ'
	   

	-- +-----------------------------------------------------------------------------------------+
	-- | CARREGA PARA UMA TABELA TEMPORARIA AS TEBALAS GENERICAS UTILIZADAS NAS CONSULTAS ABAIXO |
	-- +-----------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SX5') IS NOT NULL DROP TABLE #TEMP_SX5

	SELECT SX5.X5_TABELA, SX5.X5_CHAVE, SX5.X5_DESCRI
	INTO #TEMP_SX5
	FROM SX5010 SX5 WITH (NOLOCK) 
	WHERE	SX5.D_E_L_E_T_	= ''
		AND SX5.X5_FILIAL	= @FILIAL_SX5
		AND SX5.X5_TABELA IN (
			'21', -- Código dos grupo de tributação utilizados na tabela SF7 exceções fiscais - B1_GRTRIB
			'S0'  -- Cadastros de origem da fabricação dos produtos - B1_ORIGEM
		)
	
	-- SELECT * FROM #TEMP_SX5

	/*
-- POWER - INDICE CRIADO
CREATE NONCLUSTERED INDEX SX5010W01
ON SX5010 (X5_TABELA, X5_FILIAL, D_E_L_E_T_)
INCLUDE(X5_CHAVE, X5_DESCRI)
WITH(DATA_COMPRESSION = PAGE)
	*/

		
	-- +-----------------------------------------------------------------------------------------+
	-- | TABELA TEMPORARIA PARA ORDENACAO POR ORDEM QUE APARECE NA PESQUISA DE CODIGO            |
	-- +-----------------------------------------------------------------------------------------+
	IF object_id('tempdb.dbo.#TEMP_SEQ_COD_PRODUTO') IS NOT NULL DROP TABLE #TEMP_SEQ_COD_PRODUTO
	
	CREATE TABLE #TEMP_SEQ_COD_PRODUTO
	(
	  [CODE_PRIORITY] [int] IDENTITY(1,1) NOT NULL,
	  [B1_COD] varchar(40) COLLATE Latin1_General_100_BIN 
	)
	
	IF trim(@ProductCode) != ''
	BEGIN;
		INSERT INTO #TEMP_SEQ_COD_PRODUTO (B1_COD) 
		SELECT * FROM string_split(@ProductCode, '|');
		
		-- DELETA DUPLICIDADES
		DELETE FROM #TEMP_SEQ_COD_PRODUTO
		WHERE CODE_PRIORITY NOT IN
		(
			SELECT MAX(CODE_PRIORITY)
			FROM #TEMP_SEQ_COD_PRODUTO
			GROUP BY B1_COD
		);
	END;

	-- SELECT * FROM #TEMP_SEQ_COD_PRODUTO
	
	
	-- +-----------------------------------------------------------+
	-- | CARREGA OS DADOS DO CLIENTE QUE FOI PASSADO POR PARÂMETRO |
	-- +-----------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SA1') IS NOT NULL DROP TABLE #TEMP_SA1

	SELECT TOP 1
		SA1.A1_COD,
		SA1.A1_LOJA,
		SA1.A1_TIPO,
		SA1.A1_COND,
		SA1.A1_VEND, 
		SA1.A1_PESSOA,
		SA1.A1_TABELA,
		SA1.A1_ZGRPCLI,
		SA1.A1_GRPTRIB,
		SA1.A1_ZTIPPRC,
		SA1.A1_ZMSMPRC,
		SA1.A1_ZMAXPOR,
		SA1.A1_ZMINPOR,
		SA1.A1_GRPVEN,
		SA1.A1_EST,
		SA1.A1_COD_MUN,
		CC2.CC2_ZREGIA,
		CC2.CC2_ZMESRE,
		CC2.CC2_ZMICRE,	
		ISNULL(SA1.A1_ZVLDPRC, 0)		AS A1_ZVLDPRC,
		ISNULL(ZZ8.ZZ8_SETOR, '')		AS ZZ8_SETOR,
		IIF(ZZ8.ZZ8_SETSUP = '' OR ZZ8.ZZ8_SETSUP IS NULL, ISNULL(ZZ8.ZZ8_SETOR,''), ZZ8.ZZ8_SETSUP) AS ZZ8_SETSUP

	INTO #TEMP_SA1

	FROM SA1010 SA1 WITH (NOLOCK)

		INNER JOIN CC2010 CC2 WITH (NOLOCK) ON
				CC2.D_E_L_E_T_	= ''
			AND CC2.CC2_FILIAL	= @FILIAL_CC2
			AND CC2.CC2_EST		= SA1.A1_EST
			AND CC2.CC2_CODMUN	= SA1.A1_COD_MUN

		LEFT JOIN SA3010 SA3 WITH (NOLOCK) ON
				SA3.D_E_L_E_T_	= ''
			AND SA3.A3_FILIAL	= @FILIAL_SA3
			AND SA3.A3_COD     != ''
			AND SA3.A3_COD		= SA1.A1_VEND

		LEFT JOIN ZZ8010 ZZ8 WITH (NOLOCK) ON
				ZZ8.D_E_L_E_T_ = ''
			AND ZZ8.ZZ8_FILIAL = @FILIAL_ZZ8
			AND ZZ8.ZZ8_SETOR != ''
			AND ZZ8.ZZ8_SETOR  = SA3.A3_ZSETOR

	WHERE SA1.D_E_L_E_T_	= ''
		AND SA1.A1_FILIAL	= @FILIAL_SA1
		AND (
			-- SE FOR DO TELEVENDAS PERMITE CLIENTES BLOQUEADOS
			@ORIGN = 'KFGPEDVEN' 
			OR SA1.A1_MSBLQL  != '1'
		)
		AND SA1.A1_COD      = @CustomerCode
		AND SA1.A1_LOJA		= @CustomerStore

	-- POWER - NESSE CASO O ORDER BY É NECESSÁRIO? OU TANTO FAZ A ORDER DO REGISTRO RETORNADO NO TOP 1???
	ORDER BY SA1.A1_FILIAL, SA1.A1_COD, SA1.A1_LOJA;

	-- SELECT * FROM #TEMP_SA1

	
	-- +-------------------------------------------+
	-- | CARREGA AS TES PARA UMA TABELA TEMPORARIA |
	-- +-------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SF4') IS NOT NULL DROP TABLE #TEMP_SF4

	SELECT SF4.F4_CODIGO 
	INTO #TEMP_SF4
	FROM SF4010 SF4 WITH (NOLOCK)
	WHERE	SF4.D_E_L_E_T_	= ''
		AND SF4.F4_FILIAL	= @FILIAL_SF4
		AND SF4.F4_ESTOQUE	= 'S'
		AND SF4.F4_DUPLIC	= 'S'

	-- SELECT * FROM #TEMP_SF4

	
	-- +--------------------------------------------------------------------------------------+
	-- | MONTA UMA TEMP COM TODOS OS PRODUTOS DO CARRINHO ATUAL, PARA O TIPO DE CONSULTA CART |
	-- +--------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_CARRINHO_ATUAL') IS NOT NULL DROP TABLE #TEMP_CARRINHO_ATUAL

	SELECT 
		ZK2.ZK2_COD    AS ZK2_COD,
		ZK2.ZK2_CODNEG AS ZK2_CODNEG,
		ZK2.ZK2_ITNEGO AS ZK2_ITNEGO,
		ZK2.ZK2_ISNEG  AS ZK2_ISNEG
	
	INTO #TEMP_CARRINHO_ATUAL

	FROM ZK2010 ZK2 WITH(NOLOCK)
	
	WHERE
			ZK2.D_E_L_E_T_	= ''
		AND ZK2.ZK2_DELET  != 'S'
		AND ZK2.ZK2_FILIAL	= @FILIAL_ZK2
		AND ZK2.ZK2_IDAPP	= @SalesOrderCode
		AND @SalesOrderCode != ''

	-- SELECT * FROM #TEMP_CARRINHO_ATUAL
	

	-- TRATAMENTO PARA MELHORAR A PERFORMANCE DA TABELA INT_PRODUCTS_ALL_CATEGORIES
	IF (OBJECT_ID('tempdb..#TEMP_INT_PRODUCTS_ALL_CATEGORIES') IS NOT NULL) 
		DROP TABLE #TEMP_INT_PRODUCTS_ALL_CATEGORIES

	SELECT
		FILIAL,
		CODIGO_PRODUTO,
		CODIGO_CATEGORIA,
		DESCRICAO_CATEGORIA,
		NIVEL
	INTO #TEMP_INT_PRODUCTS_ALL_CATEGORIES
	FROM INT_PRODUCTS_ALL_CATEGORIES PRODUCTS_CATEGORIES WITH (NOLOCK)
	WHERE 
			PRODUCTS_CATEGORIES.FILIAL = @FILIAL_SB1

	-- SELECT * FROM #TEMP_INT_PRODUCTS_ALL_CATEGORIES
	
	IF (OBJECT_ID('tempdb..#TEMP_COD_DESCRICAO') IS NOT NULL) 
		DROP TABLE #TEMP_COD_DESCRICAO

	SELECT B1_COD, B1_FILIAL, DESCRICAO_CATEGORIA
	INTO #TEMP_COD_DESCRICAO
	FROM (
		SELECT 
			SB1.B1_COD, 
			B1_FILIAL,
			PRODUCTS_CATEGORIES.DESCRICAO_CATEGORIA, 
			NIVEL,
			ROW_NUMBER() OVER (PARTITION BY SB1.B1_COD ORDER BY NIVEL) AS ROWNUMBER
		FROM 
			#TEMP_INT_PRODUCTS_ALL_CATEGORIES PRODUCTS_CATEGORIES WITH (NOLOCK)
		JOIN  SB1010 SB1 WITH (NOLOCK) ON	PRODUCTS_CATEGORIES.FILIAL = @FILIAL_SB1
											AND PRODUCTS_CATEGORIES.CODIGO_PRODUTO = SB1.B1_COD
		WHERE 			
			SB1.D_E_L_E_T_	= ''
			AND SB1.B1_FILIAL	= @FILIAL_SB1
			AND SB1.B1_MSBLQL  != '1'
			AND SB1.B1_ATIVO   != 'N'
	) A
	WHERE ROWNUMBER = 1

	-- SELECT * FROM #TEMP_COD_DESCRICAO ORDER BY B1_COD
		
	IF (OBJECT_ID('tempdb..#TEMP_SB1010') IS NOT NULL) 
		DROP TABLE #TEMP_SB1010

	SELECT B1_COD, B1_POSIPI
	INTO #TEMP_SB1010
	FROM SB1010 SB1 WITH (NOLOCK)
	WHERE	SB1.D_E_L_E_T_	= ''
		AND SB1.B1_FILIAL	= @FILIAL_SB1
		AND SB1.B1_MSBLQL  != '1'
		AND SB1.B1_ATIVO   != 'N'
		AND B1_GRUPO NOT IN ('5000', '')
		AND (
			@IncludeTYPEIN = 'S' 
			OR SB1.B1_TIPO IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR = 'APP_TYPEIN')
		)
		AND (
			@IncludeGRPNOT = 'S' 
			OR SB1.B1_GRUPO NOT IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR IN ('APP_GRPNOT'))
		)
		AND (
			@IncludeGPNOEX = 'S' 
			OR SB1.B1_GRUPO NOT IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR IN ('APP_GPNOEX'))
		)
		AND (@ProductCode = '' OR SB1.B1_COD IN (SELECT value FROM STRING_SPLIT(rTrim(@ProductCode),'|')))

	-- SELECT * FROM #TEMP_SB1010
	
	IF (OBJECT_ID('tempdb..#TEMP_SYD010') IS NOT NULL) 
		DROP TABLE #TEMP_SYD010

	SELECT DISTINCT B1_POSIPI, RTRIM(SYD.YD_DESC_P) AS YD_DESC_P
	INTO #TEMP_SYD010
	FROM SYD010 SYD WITH (NOLOCK)
	JOIN #TEMP_SB1010 SB1 ON SYD.YD_TEC	= SB1.B1_POSIPI
	WHERE	SYD.D_E_L_E_T_	= ''
		AND SYD.YD_FILIAL	= @FILIAL_SYD

	-- SELECT * FROM #TEMP_SYD010
		
	IF (OBJECT_ID('tempdb..#TEMP_SC7010') IS NOT NULL) 
		DROP TABLE #TEMP_SC7010

	SELECT 
		C7_PRODUTO, MAX(C7_DATPRF) AS C7_DATPRF
	INTO #TEMP_SC7010
	FROM SC7010 SC7 WITH (NOLOCK) 
	JOIN #TEMP_SB1010 SB1 ON SC7.C7_PRODUTO = SB1.B1_COD
	WHERE
		SC7.D_E_L_E_T_ = ''
		AND SC7.C7_FILIAL = @FILIAL_SC7
		AND SC7.C7_PRODUTO != '' 
	GROUP BY C7_PRODUTO

	--SET STATISTICS IO, TIME ON

	-- POWER - PONTO DE ATENÇÃO - ESSE SELECT DEMORA DE 3 A 4 SEGUNDOS!!!

	-- +-------------------------------------------------------------------------------------------------------------------------------------+
	-- | CARREGA OS PRODUTOS PARA UMA TEBELA TEMPORARIA POREM SEM ALGUNS FILTROS POIS TEM COISAS QUE PRECISA DOS DADOS COMPLETOS SEM FILTROS |
	-- +-------------------------------------------------------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SB1_FULL') IS NOT NULL DROP TABLE #TEMP_SB1_FULL

	SELECT
		SB1.R_E_C_N_O_ AS B1_RECNO, 
		SB1.B1_COD,
		SB1.B1_DESC,

		IsNull(TCD.DESCRICAO_CATEGORIA, '') AS BM_ZDESCLI,

		SB1.B1_GRUPO,
		SB1.B1_ZMARCA,
		SB1.B1_POSIPI,
		SB1.B1_CODBAR,
		SB1.B1_ZTPEMV,
		SB1.B1_ESTSEG,
		SB1.B1_UM, 
		Space(006) AS B1_LOCKCODE,
		Space(254) AS B1_LOCKDESC,
		IsNull(SB1.B1_ZQTDVEN, 0.00) - IsNull(SB1.B1_ZQTDDEV, 0.00) AS B1_ZQTDVEN,
		CAST(ROUND(IsNull(SB1.B1_ZVLRVEN, 0.00) - IsNull(SB1.B1_ZVLRDEV, 0.00), 2, 1) AS DECIMAL (12,2)) AS B1_ZVLRVEN,		
		SB1.B1_PROC,
		SB1.B1_LOJPROC,
		SB1.B1_EMIN,
		SB1.B1_EMAX, 
		SB1.B1_GRTRIB, 
		SB1.B1_PICM, 
		SB1.B1_RASTRO, 
		SB1.B1_TIPO, 
		SB1.B1_ZCODBAR, 
		SB1.B1_ZLDTM01, 
		SB1.B1_ZLDTM02, 
		SB1.B1_ORIGEM,
		
		#TEMP_SEQ_COD_PRODUTO.CODE_PRIORITY AS ORDEM_CODIGO,
		
		SA2.A2_NREDUZ,
		SA2.A2_CGC,
		Z00.Z00_FOLDER,

		'' AS IMAGE_B01,
		'' AS IMAGE_B02,
		'' AS IMAGE_DIRECTORY,
		
		-- Upper(dbo.ufn_ConvertMemoVarchar(Z00.Z00_DESCLI, Z00.Z00_MARCA))	AS Z00_DESCLI,
		Z00.Z00_DESCLI,
		
		IsNull(SB5.B5_CEME, '')		AS B5_CEME,
		IsNull(SB5.B5_ZCODBAR, '')	AS B5_ZCODBAR,
		IsNull(SB5.B5_ZEZNAMI, '')	AS B5_ZEZNAMI,
		IsNull(SB5.B5_ZPOSOL, '')	AS B5_ZPOSOL,
		IsNull(SB5.B5_ZINDIPR, '')	AS B5_ZINDIPR,
		
		ISNULL(ZA5.ZA5_QTDEMB,  0)	AS ZA5_QTDEMB,
		ISNULL(ZA5.ZA5_DESCRI, '')	AS ZA5_DESCRI,
		
		ISNULL((
			SELECT TOP 1 TMP_SX5.X5_DESCRI 
			FROM #TEMP_SX5 TMP_SX5 
			WHERE	TMP_SX5.X5_TABELA	= 'S0' 
				AND TMP_SX5.X5_CHAVE	= SB1.B1_ORIGEM
		),'') AS B1_ORIGDES,

		ISNULL((
			SELECT TOP 1 TMP_SX5.X5_DESCRI 
			FROM #TEMP_SX5 TMP_SX5  
			WHERE	TMP_SX5.X5_TABELA	= '21' 
				AND TMP_SX5.X5_CHAVE	= SB1.B1_GRTRIB
		),'') AS B1_GRTRBDES,	

		ISNULL((
			SELECT TOP 1 SAH.AH_DESCPO
			FROM SAH010 SAH WITH (NOLOCK) 
			WHERE	SAH.D_E_L_E_T_	= ''
				AND SAH.AH_FILIAL	= @FILIAL_SAH
				AND SAH.AH_UNIMED	= SB1.B1_UM
		),'') AS B1_UMDESC,

		ISNULL((
			SELECT TOP 1 SF7.F7_VLR_ICM
			FROM SF7010 SF7 WITH (NOLOCK) 
				CROSS JOIN #TEMP_SA1 TMP_SA1 
			WHERE	SF7.D_E_L_E_T_	= ''
				AND SF7.F7_FILIAL	= @FILIAL_SF7
				AND SF7.F7_GRTRIB	= SB1.B1_GRTRIB
				AND SF7.F7_GRPCLI	= TMP_SA1.A1_GRPTRIB
				AND SF7.F7_EST		= TMP_SA1.A1_EST
				AND SF7.F7_TIPOCLI IN ('*', TMP_SA1.A1_TIPO)), '') AS F7_VLR_ICM,

		-- MELHORIA 2
		ISNULL((
			SELECT SB2.B2_QATU - SB2.B2_RESERVA - IIF(SB2.B2_STATUS != '2', SB2.B2_QEMP, 0) - SB2.B2_QACLASS - SB2.B2_QEMPSA -SB2.B2_QEMPPRJ
			FROM SB2010 SB2 WITH (NOLOCK)
			WHERE	SB2.D_E_L_E_T_	= ''
				AND SB2.B2_FILIAL	= @FILIAL_SB2
				AND SB2.B2_COD		= SB1.B1_COD
				AND SB2.B2_LOCAL	= SB1.B1_LOCPAD),0) AS B1_QATU,
							   
		ISNULL(TSY.YD_DESC_P,'') AS B1_SYDTEC,	

		(ISNULL(TSC7.C7_DATPRF, '')) AS C7_DATPRF,
		
		SB1.B1_ZPRDNOV,

		-- TROCA POR VALOR ESTATICO
		IIF(SB1.B1_ZPRDNOV >= @DATE_NOV, 'S', 'N') AS B1_ISNEW,	

		ISNULL((		
			SELECT MAX(SD2.D2_EMISSAO)
			FROM SD2010 SD2 WITH (NOLOCK)
			WHERE	SD2.D_E_L_E_T_	= '' 
				AND SD2.D2_FILIAL	= @FILIAL_SD2
				AND SD2.D2_TIPO		= 'N'
				AND SD2.D2_COD		= SB1.B1_COD
				AND SD2.D2_CLIENTE	= @CustomerCode
				AND SD2.D2_LOJA		= @CustomerStore
				AND SD2.D2_CF NOT IN ('5910','6910')
				AND EXISTS(
					SELECT TOP 1 TMP_SF4.F4_CODIGO
					FROM #TEMP_SF4 TMP_SF4
					WHERE TMP_SF4.F4_CODIGO = SD2.D2_TES))
		, '') AS D2_DTULTCP, -- PEGA PRODUTOS QUE JÁ FORAM COMPRADOS DO CLIENTE E A UTLIMA VEZ O CLIENTE COMPROU ESSE PRODUTO

		ISNULL((
			SELECT 
				PRODUCTS_CATEGORIES.CODIGO_CATEGORIA AS ACU_COD 
			FROM #TEMP_INT_PRODUCTS_ALL_CATEGORIES PRODUCTS_CATEGORIES WITH (NOLOCK)
			WHERE 
					PRODUCTS_CATEGORIES.FILIAL = @FILIAL_SB1
				AND PRODUCTS_CATEGORIES.CODIGO_PRODUTO   =  SB1.B1_COD
				
			FOR JSON AUTO, INCLUDE_NULL_VALUES 
		), '[]') AS PRODUCT_CATEGORIES_OBJECT
		
	INTO #TEMP_SB1_FULL

	FROM SB1010 SB1 WITH (NOLOCK)

	LEFT JOIN #TEMP_COD_DESCRICAO TCD WITH (NOLOCK) ON
		TCD.B1_FILIAL = @FILIAL_SB1
		AND TCD.B1_COD =  SB1.B1_COD

	LEFT JOIN #TEMP_SYD010 TSY WITH (NOLOCK) ON
		TSY.B1_POSIPI = SB1.B1_POSIPI
		
	LEFT JOIN #TEMP_SC7010 TSC7 WITH (NOLOCK) ON
		TSC7.C7_PRODUTO = SB1.B1_COD		

	LEFT JOIN Z00010 Z00 WITH (NOLOCK) ON
			Z00.D_E_L_E_T_	= ''
		AND Z00.Z00_FILIAL	= @FILIAL_Z00
		AND Z00.Z00_CODIGO  = SB1.B1_ZMARCA

	LEFT JOIN ZA5010 ZA5 WITH (NOLOCK) ON 
			ZA5.D_E_L_E_T_ = ''
		AND ZA5.ZA5_FILIAL = @FILIAL_ZA5
		AND ZA5.ZA5_CODIGO = SB1.B1_ZTPEMV			
			
	LEFT JOIN SB5010 SB5 WITH (NOLOCK) ON
			SB5.D_E_L_E_T_	= ''
		AND SB5.B5_FILIAL	= @FILIAL_SB5
		AND SB5.B5_COD		= SB1.B1_COD

	LEFT JOIN SA2010 SA2 WITH (NOLOCK) ON
			SA2.D_E_L_E_T_	= ''
		AND SA2.A2_FILIAL	= @FILIAL_SA2
		AND SA2.A2_COD		= SB1.B1_PROC
		AND SA2.A2_LOJA		= SB1.B1_LOJPROC
			
	LEFT JOIN #TEMP_SEQ_COD_PRODUTO ON
			#TEMP_SEQ_COD_PRODUTO.B1_COD = SB1.B1_COD

	WHERE	SB1.D_E_L_E_T_	= ''
		AND SB1.B1_FILIAL	= @FILIAL_SB1
		AND SB1.B1_MSBLQL  != '1'
		AND SB1.B1_ATIVO   != 'N'
		AND B1_GRUPO NOT IN ('5000', '')
		AND (
			@IncludeTYPEIN = 'S' 
			OR SB1.B1_TIPO IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR = 'APP_TYPEIN')
		)
		AND (
			@IncludeGRPNOT = 'S' 
			OR SB1.B1_GRUPO NOT IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR IN ('APP_GRPNOT'))
		)
		AND (
			@IncludeGPNOEX = 'S' 
			OR SB1.B1_GRUPO NOT IN (SELECT X6_VALUE FROM #TEMP_SX6 WHERE X6_VAR IN ('APP_GPNOEX'))
		)
		AND (@ProductCode = '' OR SB1.B1_COD IN (SELECT value FROM STRING_SPLIT(rTrim(@ProductCode),'|')))

		AND (@SearchFilter = ''
			OR(	   ('B1_COD'     IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB1.B1_COD		LIKE '%' + @SearchFilter + '%' )
				OR ('B1_PROC'    IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB1.B1_PROC		LIKE '%' + @SearchFilter + '%' )
				OR ('B1_DESC'    IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB1.B1_DESC		LIKE '%' + @SearchFilter + '%' )
				OR ('B1_ZCODBAR' IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB1.B1_ZCODBAR	LIKE '%' + @SearchFilter + '%' )
				OR ('B1_CODBAR'  IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB1.B1_CODBAR	LIKE '%' + @SearchFilter + '%' )
				OR ('B5_ZPOSOL'  IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB5.B5_ZPOSOL	LIKE '%' + @SearchFilter + '%' )
				OR ('B5_ZINDIPR' IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB5.B5_ZINDIPR	LIKE '%' + @SearchFilter + '%' )
				OR ('B5_CEME'    IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  SB5.B5_CEME		LIKE '%' + @SearchFilter + '%' )
				OR (
					'ACU_DESC' IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    
					AND EXISTS (
						SELECT TOP 1 CODIGO_PRODUTO
						FROM INT_PRODUCTS_ALL_CATEGORIES
						WHERE
								FILIAL = @FILIAL_SB1
							AND CODIGO_PRODUTO = SB1.B1_COD
							AND DESCRICAO_CATEGORIA LIKE '%' + @SearchFilter + '%'
					)
				)
				OR ('Z00_MARCA'  IN (SELECT value FROM STRING_SPLIT(rTrim(@SearchFields), '|'))    AND  Z00.Z00_MARCA	LIKE '%' + @SearchFilter + '%' ) 
			)
		)

		AND (
			-- SE O QUERY TYPE FOR ORDER FAZ UM PRE FILTRO PARA OTIMIZACAO
			@QueryResult <> 'ORDER'
			OR EXISTS (
				SELECT TOP 1 
					TEMP_CARRINHO_ATUAL.ZK2_COD 
				FROM #TEMP_CARRINHO_ATUAL TEMP_CARRINHO_ATUAL
				WHERE 
					TEMP_CARRINHO_ATUAL.ZK2_COD = SB1.B1_COD
			)
		)
		
	--SET STATISTICS IO, TIME OFF


	
/*
-- MELHORIA 1
-- ANTES 
Table '#TEMP_SX2_0000004B0636'. Scan count 9907, logical reads 9907
Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 9906, logical reads 32082
Table 'SB1010'. Scan count 5, logical reads 2185

 SQL Server Execution Times:
   CPU time = 501 ms,  elapsed time = 846 ms.

-- DEPOIS
Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 9906, logical reads 19842
Table '#TEMP_SX2_0000004B0D52'. Scan count 2, logical reads 9907
Table 'SB1010'. Scan count 1, logical reads 2185

 SQL Server Execution Times:
   CPU time = 172 ms,  elapsed time = 624 ms.

-- CRIA INDICE
USE DADOSPROD

CREATE NONCLUSTERED INDEX INT_PRODUCTS_ALL_CATEGORIESW01
ON INT_PRODUCTS_ALL_CATEGORIES (CODIGO_PRODUTO, FILIAL, NIVEL)
INCLUDE(DESCRICAO_CATEGORIA)
WITH(DATA_COMPRESSION = PAGE)


-- MELHORIA 2
-- ANTES
Table 'SB2010'. Scan count 9906, logical reads 48786
Table '#TEMP_SX2_0000004B1B83'. Scan count 9909, logical reads 19847
Table 'SAH010'. Scan count 1, logical reads 91
Table 'Worktable'. Scan count 9906, logical reads 21512, physical reads 0, read-ahead reads 954
Table '#TEMP_SX5_0000004B1B85'. Scan count 2, logical reads 72
Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 9906, logical reads 19842
Table 'Worktable'. Scan count 0, logical reads 0
Table 'SB1010'. Scan count 1, logical reads 2185

 SQL Server Execution Times:
   CPU time = 438 ms,  elapsed time = 1068 ms.

-- DEPOIS
Table 'SB2010'. Scan count 9906, logical reads 19870
Table '#TEMP_SX2_0000004B1BA9'. Scan count 9909, logical reads 19847
Table 'SAH010'. Scan count 1, logical reads 91
Table 'Worktable'. Scan count 9906, logical reads 21512
Table '#TEMP_SX5_0000004B1BAB'. Scan count 2, logical reads 72
Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 9906, logical reads 19842
Table 'Worktable'. Scan count 0, logical reads 0
Table 'SB1010'. Scan count 1, logical reads 2185

 SQL Server Execution Times:
   CPU time = 453 ms,  elapsed time = 905 ms.

-- CRIA INDICE
CREATE NONCLUSTERED INDEX SB2010W02
ON SB2010(B2_COD, B2_LOCAL, B2_FILIAL, D_E_L_E_T_)
INCLUDE(B2_RESERVA, B2_QEMP, B2_QATU, B2_QEMPSA, B2_QEMPPRJ, B2_QEMPPRE, B2_QTNP, B2_QEMPN, B2_QACLASS, B2_STATUS)
WITH(DATA_COMPRESSION = PAGE)

*/

	

/*
-- ANTES
Table 'Worktable'. Scan count 59038, logical reads 234854

Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 19812, logical reads 52005
Table '#TEMP_SX2______0000004AEFA0'. Scan count 29728, logical reads 41716
Table 'SB2010'. Scan count 9906, logical reads 48786
Table 'SC7010'. Scan count 9906, logical reads 29719
Table '#TEMP_SB1_FULL_0000004AEFA8'. Scan count 0, logical reads 12194
Table 'SYD010'. Scan count 1247, logical reads 6235

Table 'Workfile'. Scan count 0, logical reads 0
Table '#TEMP_SX6______0000004AEFA1'. Scan count 1, logical reads 1
Table 'SF7010'. Scan count 1, logical reads 283
Table '#TEMP_SA1______0000004AEFA5'. Scan count 687, logical reads 687
Table 'SAH010'. Scan count 1, logical reads 91
Table '#TEMP_SX5______0000004AEFA3'. Scan count 2, logical reads 72
Table 'Worktable'. Scan count 0, logical reads 0
Table 'Z00010'. Scan count 1, logical reads 38
Table 'SB1010'. Scan count 1, logical reads 2185
Table 'ZA5010'. Scan count 1, logical reads 4
Table 'SB5010'. Scan count 1, logical reads 1925
Table 'SA2010'. Scan count 2, logical reads 77
Table '#TEMP_SEQ_COD_PRODUTO_0000004AEFA4'. Scan count 1, logical reads 0
Table '#TEMP_SF4______0000004AEFA6'. Scan count 1, logical reads 2
Table 'SD2010'. Scan count 1, logical reads 6

 SQL Server Execution Times:
   CPU time = 2594 ms,  elapsed time = 5849 ms.

-- DEPOIS
Table 'Worktable'. Scan count 59039, logical reads 235262
Table '#TEMP_SB1_FULL_0000004DB613'. Scan count 0, logical reads 12238
Table '#TEMP_SX2_0000004DB60C'. Scan count 19825, logical reads 41720
Table 'INT_PRODUCTS_ALL_CATEGORIES'. Scan count 19814, logical reads 39795
Table 'SC7010'. Scan count 9907, logical reads 29722
Table 'SB2010'. Scan count 9907, logical reads 19885

SQL Server Execution Times:
   CPU time = 2328 ms,  elapsed time = 3478 ms.
*/
	
	--SELECT * FROM #TEMP_SB1_FULL

	
	-- +--------------------------------------------------------------------------------------+
	-- | CARREGA OS PRODUTOS PARA UMA TEBELA TEMPORARIA AGORA SIM FILTRANDO O QUE FOI PASSADO |
	-- +--------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_SB1') IS NOT NULL DROP TABLE #TEMP_SB1;

	SELECT 
		TMP_SB1_FULL.*
	INTO #TEMP_SB1
	FROM #TEMP_SB1_FULL TMP_SB1_FULL
	WHERE	
		(
			rTrim(@CategoryCode) = '' 
			OR EXISTS(
				SELECT 
					TOP 1 PRODUCTS_CATEGORIES.CODIGO_PRODUTO 
				FROM INT_PRODUCTS_ALL_CATEGORIES PRODUCTS_CATEGORIES WITH (NOLOCK)
				WHERE 
						PRODUCTS_CATEGORIES.FILIAL = @FILIAL_SB1
					AND	PRODUCTS_CATEGORIES.CODIGO_CATEGORIA IN (SELECT value FROM STRING_SPLIT(rTrim(@CategoryCode), '|'))
					AND PRODUCTS_CATEGORIES.CODIGO_PRODUTO   =  TMP_SB1_FULL.B1_COD
			)
		)
		AND (rTrim(@BrandCode) = '' OR TMP_SB1_FULL.B1_ZMARCA IN (SELECT value FROM STRING_SPLIT(rTrim(@BrandCode), '|')))
				
	-- +------------------------------------------------------------------------------------------+
	-- | PREÇO DE TABELA, BUSCA A TABELA DE PREÇO DO CLIENTE PORÉM SOMENTE PRODUTOS QUE TEM PREÇO |
	-- +------------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_DA1') IS NOT NULL DROP TABLE #TEMP_DA1

	SELECT 
		DA1.R_E_C_N_O_,
		DA1.DA1_CODTAB,
		DA1.DA1_CODPRO,
		DA1.DA1_ZPRCMI,
		DA1.DA1_PRCVEN,
		DA1.DA1_PRCMAX,
		DA1.DA1_ZPRCES,
		dbo.ufn_GetCustomerPrice(TMP_SA1.A1_ZTIPPRC, DA1.DA1_ZPRCMI, DA1.DA1_PRCVEN, DA1.DA1_PRCMAX, DA1.DA1_ZPRCES, 1, 0, 0, 0) AS DA1_PRECO

	INTO #TEMP_DA1

	FROM DA1010 DA1 WITH (NOLOCK)	
		CROSS JOIN #TEMP_SA1 TMP_SA1

	WHERE	DA1.D_E_L_E_T_ = ''
		AND DA1.DA1_FILIAL = @FILIAL_DA1
		AND DA1.DA1_CODTAB = TMP_SA1.A1_TABELA
		AND DA1.DA1_ATIVO  = '1'
		AND EXISTS(
			SELECT TOP 1 DA0.DA0_CODTAB 
			FROM DA0010 DA0 WITH (NOLOCK)
			WHERE	DA0.D_E_L_E_T_	= ''
				AND DA0.DA0_FILIAL  = DA1.DA1_FILIAL
				AND DA0.DA0_CODTAB	= DA1.DA1_CODTAB
				AND DA0.DA0_ATIVO	= '1'
		)
		AND EXISTS(
			SELECT TOP 1 TMP_SB1_FULL.B1_COD
			FROM #TEMP_SB1_FULL TMP_SB1_FULL
			WHERE 
				TMP_SB1_FULL.B1_COD = DA1.DA1_CODPRO
		)

	ORDER BY DA1.DA1_FILIAL, DA1.DA1_CODTAB, DA1.DA1_CODPRO
	 
	-- +------------------------------------------------------------------------------------------------------------------------------------------+
	-- | BUSCA UM CARRINHO QUANDO PASSADO POR PARAMETRO, OU SE NÃO PASSAR PEGA O ULTIMO CARRINHO ATIVO. PEGA SOMENTE PEDIDOS DO PORTAL DO CLIENTE |
	-- +------------------------------------------------------------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_ZK2') IS NOT NULL DROP TABLE #TEMP_ZK2

	SELECT 
		ZK2.ZK2_FILIAL,
		ZK2.ZK2_IDAPP,
		ZK2.ZK2_ITEAPP,
		ZK2.ZK2_COD,
		ZK2.ZK2_QUANT,
		ZK2.ZK2_CODNEG,
		ZK2.ZK2_ITNEGO,
		ZK2.ZK2_ISNEG,
		ZK2.R_E_C_N_O_ AS ZK2RECNO,
		ZK1.R_E_C_N_O_ AS ZK1RECNO
	
	INTO #TEMP_ZK2

	FROM ZK1010 ZK1
		
		INNER JOIN ZK2010 ZK2 ON
				ZK2.D_E_L_E_T_	= ''
			AND ZK2.ZK2_DELET  != 'S'
			AND ZK2.ZK2_TPOPER	= '01'
			AND ZK2.ZK2_FILIAL	= ZK1.ZK1_FILIAL
			AND ZK2.ZK2_IDAPP	= ZK1.ZK1_IDAPP
		
		INNER JOIN #TEMP_SB1 TEMP_SB1 ON
			TEMP_SB1.B1_COD = ZK2.ZK2_COD

		CROSS JOIN #TEMP_SA1 TMP_SA1

	WHERE	ZK1.D_E_L_E_T_	= ''
		AND ZK1.ZK1_DELET  != 'S'
		AND ZK1.ZK1_FILIAL	= @FILIAL_ZK1
		AND ZK1.ZK1_CLIENT	= TMP_SA1.A1_COD
		AND ZK1.ZK1_LOJA	= TMP_SA1.A1_LOJA
		AND((	@SalesOrderCode = ''
				AND ZK1.R_E_C_N_O_	= (
					SELECT MAX(ZK1MAX.R_E_C_N_O_)
					FROM ZK1010 ZK1MAX 
					WHERE	ZK1MAX.D_E_L_E_T_	= ''
						AND ZK1MAX.ZK1_DELET   != 'S'
						AND ZK1MAX.ZK1_FILIAL	= ZK1.ZK1_FILIAL
						AND ZK1MAX.ZK1_CLIENT	= ZK1.ZK1_CLIENT
						AND ZK1MAX.ZK1_LOJA		= ZK1.ZK1_LOJA
						AND ZK1MAX.ZK1_STATUS	= ZK1.ZK1_STATUS
						AND ZK1MAX.ZK1_ORIGEM	= ZK1.ZK1_ORIGEM
						AND ZK1MAX.ZK1_STATUS	= IIF(@Orign = 'KFGPORCLI', 'C', 'R')
						AND ZK1MAX.ZK1_ORIGEM	= @Orign
					)	
			)
			OR(@SalesOrderCode != '' AND ZK1.ZK1_IDAPP = @SalesOrderCode)
		)

	ORDER BY ZK2.ZK2_FILIAL, ZK2.ZK2_IDAPP, ZK2.ZK2_ITEAPP, ZK2.ZK2_COD
	
	-- +----------------------------------------------------------------------------------------------+
	-- | TABELA BASE PARA OUTRAS CONSULTA, NESSA TEMP TEM OS DADOS BASE PARA MONTAGEM DE VARIAS QUERY |
	-- +----------------------------------------------------------------------------------------------+
	IF OBJECT_ID('tempdb..#TEMP_DEFAULT') IS NOT NULL DROP TABLE #TEMP_DEFAULT

	SELECT
		'DA1'                                       AS ORIGEM,		
		rTrim(TMP_SB1_FULL.B1_COD)					AS B1_COD,
		rTrim(TMP_SB1_FULL.B1_DESC)					AS B1_DESC,
		rTrim(TMP_SB1_FULL.B1_UM)					AS B1_UM,
		rTrim(TMP_SB1_FULL.B1_UMDESC)				AS B1_UMDESC,
		rTrim(TMP_SB1_FULL.B1_ZMARCA)				AS B1_ZMARCA,
		rTrim(TMP_SB1_FULL.Z00_DESCLI)				AS Z00_DESCLI,
		rTrim(TMP_SB1_FULL.Z00_FOLDER)				AS Z00_FOLDER,
		rTrim(TMP_SB1_FULL.IMAGE_B01)				AS IMAGE_B01,
		rTrim(TMP_SB1_FULL.IMAGE_B02)				AS IMAGE_B02,
		rTrim(TMP_SB1_FULL.IMAGE_DIRECTORY)			AS IMAGE_DIRECTORY,
		IsNull(rTrim(TMP_SB1_FULL.B1_ZPRDNOV), '')	AS B1_ZPRDNOV,
		IsNull(TMP_SB1_FULL.B1_ISNEW, 'N')			AS B1_ISNEW,
		TMP_SB1_FULL.D2_DTULTCP						AS D2_DTULTCP,			
		TMP_SB1_FULL.B5_ZEZNAMI						AS B5_ZEZNAMI,			
		TMP_SB1_FULL.B1_QATU						AS B1_QATU,
		TMP_SB1_FULL.B1_ESTSEG						AS B1_ESTSEG,
		rTrim(TMP_SB1_FULL.B1_GRUPO)				AS B1_GRUPO,
		TMP_SB1_FULL.B1_EMIN                        AS B1_EMIN,
		TMP_SB1_FULL.B1_EMAX						AS B1_EMAX, 
		TMP_SB1_FULL.B1_GRTRIB						AS B1_GRTRIB, 
		TMP_SB1_FULL.B1_PICM						AS B1_PICM, 
		TMP_SB1_FULL.B1_RASTRO						AS B1_RASTRO, 
		TMP_SB1_FULL.B1_TIPO						AS B1_TIPO, 
		TMP_SB1_FULL.B1_ZCODBAR						AS B1_ZCODBAR, 
		TMP_SB1_FULL.B1_ZLDTM01						AS B1_ZLDTM01, 
		TMP_SB1_FULL.B1_ZLDTM02						AS B1_ZLDTM02, 
		TMP_SB1_FULL.BM_ZDESCLI						AS BM_ZDESCLI,
		rTrim(TMP_SB1_FULL.B1_GRTRBDES)             AS B1_GRTRBDES,
		rTrim(TMP_SB1_FULL.B1_SYDTEC)             	AS B1_SYDTEC,
		rTrim(TMP_SB1_FULL.B1_POSIPI)				AS B1_POSIPI,
		rTrim(TMP_SB1_FULL.B1_CODBAR)				AS B1_CODBAR,
		rTrim(TMP_SB1_FULL.B1_ORIGEM)				AS B1_ORIGEM,
		rTrim(TMP_SB1_FULL.B1_ORIGDES)				AS B1_ORIGDES,
		
		TMP_SB1_FULL.ORDEM_CODIGO        AS ORDEM_CODIGO,
		
		rTrim(TMP_SB1_FULL.B5_ZCODBAR)				AS B5_ZCODBAR,	
		rTrim(TMP_SB1_FULL.B5_CEME)					AS B5_CEME,
		rTrim(TMP_SB1_FULL.B5_ZPOSOL)				AS B5_ZPOSOL,
		rTrim(TMP_SB1_FULL.B5_ZINDIPR)				AS B5_ZINDIPR,
		rTrim(TMP_SB1_FULL.A2_NREDUZ)				AS A2_NREDUZ,
		rTrim(TMP_SB1_FULL.A2_CGC)				    AS A2_CGC,
		rTrim(TMP_SB1_FULL.F7_VLR_ICM)				AS F7_VLR_ICM,
		''											AS D2_DOC,
		''											AS D2_SERIE,
		''											AS D2_CLIENTE,
		''											AS D2_LOJA,
		''											AS D2_ITEM,	
		''											AS D2_EMISSAO,		
		TMP_DA1.DA1_PRECO							AS PRECO_TABELA,	-- PADRAO DO CLIENTE SE PEGOU DA SD2 O DA1
		rTrim(IsNull(TMP_SB1_FULL.B1_ZTPEMV,''))	AS B1_ZTPEMV,
		IsNull(TMP_SB1_FULL.ZA5_QTDEMB,0)			AS ZA5_QTDEMB,
		rTrim(IsNull(TMP_SB1_FULL.ZA5_DESCRI,''))	AS ZA5_DESCRI,
		TMP_SB1_FULL.B1_ZQTDVEN						AS B1_ZQTDVEN, 
		TMP_SB1_FULL.B1_ZVLRVEN						AS B1_ZVLRVEN, 
		rTrim(TMP_SB1_FULL.B1_LOCKCODE)				AS ZL0_CODIGO,
		rTrim(TMP_SB1_FULL.B1_LOCKDESC)				AS ZL0_DESCRI,
		''											AS ZZQ_CODIGO, 
		''											AS ZZQ_CORCAB,
		''											AS ZZQ_CORTXT,
		''											AS ZZQ_TITCAB,
		''											AS ZZQ_DESCLI,
		''											AS ZZQ_DTFIN,
		''											AS ZZQ_DATCAD,
		''											AS ZZQ_HORCAD,
		''											AS ZZQ_TIPOPR,
		0.00										AS ZZQ_ZZR_COMISS,
		'N'											AS ZZQ_ZZR_COMCUS,
		'N'											AS ZZR_EDIQTD,
		''											AS ZZQ_IMGBAN,
		''											AS ZZR_IMGBAN,
		''											AS ZZR_ESCBON,
		''											AS ZZR_MULTBO,
		0.00										AS ZZR_QUANT,
		''											AS ZZR_ITEM,
		''											AS ZZR_TPOPER,
		''											AS ZZR_VLDPRD,
		'I'											AS ZZR_UTLLOT,
		''											AS ZZR_ARMAZE,
		''											AS ZZR_LOTE,
		''											AS ZZR_ENDER,
		0.00										AS ZZR_PERDES,
		ISNULL(TMP_DA1.DA1_ZPRCMI, 0.00)            AS DA1_ZPRCMI,
		ISNULL(TMP_DA1.DA1_PRCMAX, 0.00)            AS DA1_PRCMAX,
		ISNULL(TMP_DA1.DA1_PRCVEN, 0.00)            AS DA1_PRCVEN,
		TMP_DA1.DA1_PRECO							AS VALIDACAO_PRECO,			-- PREÇO QUE O CLIENTE VAI PAGAR
		TMP_DA1.DA1_PRECO							AS PRECO_PADRAO_CLIENTE,	-- PREÇO PADRAO DO CLIENTE
		0.00																							AS PRECO_RISCADO,	-- PREÇO QUE VAI APARECER RISCADO
		TMP_DA1.DA1_PRECO							AS PRECO_APAGAR,	-- PREÇO QUE O CLIENTE VAI PAGAR
		TMP_SB1_FULL.C7_DATPRF                      AS C7_DATPRF,
		'[]'										AS BONIFICACAO_OBJ,
		rTrim(IsNull(TMP_ZK2.ZK2_FILIAL, ''))		AS ZK2_FILIAL,
		rTrim(IsNull(TMP_ZK2.ZK2_IDAPP, ''))		AS ZK2_IDAPP,
		rTrim(IsNull(TMP_ZK2.ZK2_ITEAPP, ''))		AS ZK2_ITEAPP,
		rTrim(IsNull(TMP_ZK2.ZK2_COD, ''))			AS ZK2_COD,
		IsNull(TMP_ZK2.ZK2_QUANT, 0)				AS ZK2_QUANT,
		rTrim(IsNull(TMP_ZK2.ZK2_CODNEG, ''))		AS ZK2_CODNEG,
		rTrim(IsNull(TMP_ZK2.ZK2_ITNEGO, ''))		AS ZK2_ITNEGO,
		IsNull(TMP_ZK2.ZK2RECNO, 0)					AS ZK2RECNO,
		IsNull(TMP_ZK2.ZK1RECNO, 0)					AS ZK1RECNO,
		'N'											AS EXISTS_PROMOTION,
		0											AS ZZR_RECNO,
		TMP_SB1_FULL.PRODUCT_CATEGORIES_OBJECT      AS PRODUCT_CATEGORIES_OBJECT

	INTO #TEMP_DEFAULT

	FROM #TEMP_SB1_FULL TMP_SB1_FULL

		LEFT JOIN #TEMP_DA1 TMP_DA1 ON
				TMP_DA1.DA1_CODPRO	= TMP_SB1_FULL.B1_COD

		LEFT JOIN #TEMP_ZK2 TMP_ZK2 ON
				TMP_ZK2.ZK2_COD	= TMP_SB1_FULL.B1_COD
			AND (  (TMP_ZK2.ZK2_CODNEG	= '' AND TMP_ZK2.ZK2_ITNEGO	 = '')
				OR (TMP_ZK2.ZK2_CODNEG != ''  AND TMP_ZK2.ZK2_ISNEG = 'S')
			)
			
	WHERE 
		(
			-- SE FOR DO TELEVENDAS PERMITE ITENS SEM TABELA DE PRECO / PRECO ZERADO
			@ORIGN = 'KFGPEDVEN' 
			OR TMP_DA1.DA1_PRECO > 0
		)
			
	ORDER BY TMP_SB1_FULL.B1_COD


	-- +-----------------------------------------------------------+
	-- | BUSCA AS PROMOÇÕES CADASTRADAS QUE O CLIENTE SE ENQUADROU |
	-- +-----------------------------------------------------------+
	IF @PromotionQueryExecute = 1 OR @MainQueryExecute = 1
	BEGIN;

		-- +------------------------------------------------------------------------------------------+
		-- | BUSCA AS PROMOÇÕES SEM ALGUNS FILTROS POIS PRECISA EM ALGUNS LOCAIS OS DADOS SEM FILTROS |
		-- +------------------------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_PROMOTION_FULL') IS NOT NULL DROP TABLE #TEMP_PROMOTION_FULL

		SELECT  
			'ZZQ'											AS ORIGEM,		
			rTrim(TMP_SB1_FULL.B1_COD)						AS B1_COD,
			rTrim(TMP_SB1_FULL.B1_DESC)						AS B1_DESC,			
			rTrim(TMP_SB1_FULL.B1_UM)						AS B1_UM,
			rTrim(TMP_SB1_FULL.B1_UMDESC)					AS B1_UMDESC,
			rTrim(TMP_SB1_FULL.B1_ZMARCA)					AS B1_ZMARCA,
			rTrim(TMP_SB1_FULL.Z00_DESCLI)					AS Z00_DESCLI,
			rTrim(TMP_SB1_FULL.Z00_FOLDER)					AS Z00_FOLDER,
			rTrim(TMP_SB1_FULL.IMAGE_B01)					AS IMAGE_B01,
			rTrim(TMP_SB1_FULL.IMAGE_B02)					AS IMAGE_B02,
			rTrim(TMP_SB1_FULL.IMAGE_DIRECTORY)				AS IMAGE_DIRECTORY,
			IsNull(rTrim(TMP_SB1_FULL.B1_ZPRDNOV), '')		AS B1_ZPRDNOV,
			IsNull(TMP_SB1_FULL.B1_ISNEW,'N')				AS B1_ISNEW,			
			TMP_SB1_FULL.D2_DTULTCP							AS D2_DTULTCP,	
			TMP_SB1_FULL.B5_ZEZNAMI							AS B5_ZEZNAMI,	
			TMP_SB1_FULL.B1_QATU							AS B1_QATU,		
			TMP_SB1_FULL.B1_ESTSEG							AS B1_ESTSEG,
			rTrim(TMP_SB1_FULL.B1_GRUPO)					AS B1_GRUPO,
			TMP_SB1_FULL.B1_EMIN                            AS B1_EMIN,
			TMP_SB1_FULL.B1_EMAX						AS B1_EMAX, 
			TMP_SB1_FULL.B1_GRTRIB						AS B1_GRTRIB, 
			TMP_SB1_FULL.B1_PICM						AS B1_PICM, 
			TMP_SB1_FULL.B1_RASTRO						AS B1_RASTRO, 
			TMP_SB1_FULL.B1_TIPO						AS B1_TIPO, 
			TMP_SB1_FULL.B1_ZCODBAR						AS B1_ZCODBAR, 
			TMP_SB1_FULL.B1_ZLDTM01						AS B1_ZLDTM01, 
			TMP_SB1_FULL.B1_ZLDTM02						AS B1_ZLDTM02, 
			TMP_SB1_FULL.BM_ZDESCLI						AS BM_ZDESCLI,
			rTrim(TMP_SB1_FULL.B1_GRTRBDES)             AS B1_GRTRBDES,
			rTrim(TMP_SB1_FULL.B1_SYDTEC)             	AS B1_SYDTEC,
		
			rTrim(TMP_SB1_FULL.B1_POSIPI)					AS B1_POSIPI,
			rTrim(TMP_SB1_FULL.B1_CODBAR)					AS B1_CODBAR,
			rTrim(TMP_SB1_FULL.B1_ORIGEM)					AS B1_ORIGEM,
			rTrim(TMP_SB1_FULL.B1_ORIGDES)					AS B1_ORIGDES,
			
			TMP_SB1_FULL.ORDEM_CODIGO                       AS ORDEM_CODIGO,
			
			rTrim(TMP_SB1_FULL.B5_ZCODBAR)					AS B5_ZCODBAR,	
			rTrim(TMP_SB1_FULL.B5_CEME)						AS B5_CEME,
			rTrim(TMP_SB1_FULL.B5_ZPOSOL)					AS B5_ZPOSOL,
			rTrim(TMP_SB1_FULL.B5_ZINDIPR)					AS B5_ZINDIPR,
			rTrim(TMP_SB1_FULL.A2_NREDUZ)					AS A2_NREDUZ,
			rTrim(TMP_SB1_FULL.A2_CGC)						AS A2_CGC,
			rTrim(TMP_SB1_FULL.F7_VLR_ICM)					AS F7_VLR_ICM,
			''												AS D2_DOC,
			''												AS D2_SERIE,
			''												AS D2_CLIENTE,
			''												AS D2_LOJA,
			''												AS D2_ITEM,	
			''												AS D2_EMISSAO,
			TMP_DA1.DA1_PRECO								AS PRECO_TABELA,	-- PADRAO DO CLIENTE SE PEGOU DA SD2 O DA1
			rTrim(IsNull(TMP_SB1_FULL.B1_ZTPEMV,''))		AS B1_ZTPEMV,
			IsNull(TMP_SB1_FULL.ZA5_QTDEMB,0)				AS ZA5_QTDEMB,
			rTrim(IsNull(TMP_SB1_FULL.ZA5_DESCRI,''))		AS ZA5_DESCRI,
			TMP_SB1_FULL.B1_ZQTDVEN							AS B1_ZQTDVEN,		
			TMP_SB1_FULL.B1_ZVLRVEN							AS B1_ZVLRVEN,		
			rTrim(TMP_SB1_FULL.B1_LOCKCODE)					AS ZL0_CODIGO,
			rTrim(TMP_SB1_FULL.B1_LOCKDESC)					AS ZL0_DESCRI,
			RTRIM(ISNULL(ZZQ.ZZQ_CODIGO, ''))				AS ZZQ_CODIGO, 
			(CASE
				WHEN ZZR.ZZR_CORCAB IS NOT NULL AND ZZR.ZZR_CORCAB != '' THEN RTRIM(ISNULL(ZZR.ZZR_CORCAB, ''))
				ELSE RTRIM(ISNULL(ZZQ.ZZQ_CORCAB, ''))
			END)											AS ZZQ_CORCAB,
			(CASE
				WHEN ZZR.ZZR_CORTXT IS NOT NULL AND ZZR.ZZR_CORTXT != '' THEN RTRIM(ISNULL(ZZR.ZZR_CORTXT, ''))
				ELSE RTRIM(ISNULL(ZZQ.ZZQ_CORTXT, ''))
			END)											AS ZZQ_CORTXT,
			(CASE
				WHEN ZZR.ZZR_TITCAB IS NOT NULL AND ZZR.ZZR_TITCAB != '' THEN RTRIM(ISNULL(ZZR.ZZR_TITCAB, ''))
				ELSE RTRIM(ISNULL(ZZQ.ZZQ_TITCAB, ''))
			END)											AS ZZQ_TITCAB,
			RTRIM(ISNULL(ZZQ.ZZQ_DESCLI, ''))				AS ZZQ_DESCLI,
			RTRIM(ISNULL(ZZQ.ZZQ_DTFIN, ''))				AS ZZQ_DTFIN,
			RTRIM(ISNULL(ZZQ.ZZQ_DATCAD, ''))				AS ZZQ_DATCAD,
			RTRIM(ISNULL(ZZQ.ZZQ_HORCAD, ''))				AS ZZQ_HORCAD,
			RTRIM(ISNULL(ZZQ.ZZQ_TIPOPR, ''))				AS ZZQ_TIPOPR,			
			(CASE
				WHEN ZZR.ZZR_COMIS1 IS NOT NULL AND ZZR.ZZR_COMIS1 > 0.00 AND rTrim(ZZR.ZZR_COMCUS) = 'S' THEN ZZR.ZZR_COMIS1
				WHEN ZZQ.ZZQ_COMIS1 IS NOT NULL AND ZZQ.ZZQ_COMIS1 > 0.00 AND rTrim(ZZQ.ZZQ_COMCUS) = 'S' THEN ZZQ.ZZQ_COMIS1 
				ELSE 0.00
			END)											AS ZZQ_ZZR_COMISS,
			(CASE
				WHEN rTrim(ZZR.ZZR_COMCUS) = 'S' THEN 'S'
				WHEN rTrim(ZZQ.ZZQ_COMCUS) = 'S' THEN 'S'
				ELSE 'N'
			END)											AS ZZQ_ZZR_COMCUS, 
			RTRIM(ISNULL(ZZR.ZZR_EDIQTD , 'N'))				AS ZZR_EDIQTD,
			(CASE
				WHEN @ConcatRouteImage != 'S'	THEN ''
				WHEN ZZQ.ZZQ_IMGBAN		= ''	THEN ''
				WHEN ZZQ.ZZQ_IMGBAN  IS NULL	THEN ''
				WHEN UPPER(SUBSTRING(ZZQ.ZZQ_IMGBAN,1,7)) = 'IMAGES/' THEN ''
				ELSE 'images/'
			END) + RTRIM(ISNULL(ZZQ.ZZQ_IMGBAN, ''))		AS ZZQ_IMGBAN, 
			(CASE
				WHEN @ConcatRouteImage != 'S'	THEN ''
				WHEN ZZR.ZZR_IMGBAN		= ''	THEN ''
				WHEN ZZR.ZZR_IMGBAN  IS NULL	THEN ''
				WHEN UPPER(SUBSTRING(ZZR.ZZR_IMGBAN,1,7)) = 'IMAGES/' THEN ''
				ELSE 'images/'
			END) + RTRIM(ISNULL(ZZR.ZZR_IMGBAN, ''))		AS ZZR_IMGBAN, 
			RTRIM(ISNULL(ZZR.ZZR_ESCBON, ''))				AS ZZR_ESCBON,
			RTRIM(ISNULL(ZZR.ZZR_MULTBO, ''))				AS ZZR_MULTBO,
			ISNULL(ZZR.ZZR_QUANT, 0.00)						AS ZZR_QUANT,
			RTRIM(ISNULL(ZZR.ZZR_ITEM, ''))					AS ZZR_ITEM,
			RTRIM(ISNULL(ZZR.ZZR_TPOPER, ''))				AS ZZR_TPOPER,
			RTRIM(ISNULL(ZZR.ZZR_VLDPRD, ''))				AS ZZR_VLDPRD,
			RTRIM(ISNULL(ZZR.ZZR_UTLLOT, 'I'))				AS ZZR_UTLLOT,	
			RTRIM(ISNULL(ZZR.ZZR_ARMAZE, ''))				AS ZZR_ARMAZE,		
			RTRIM(ISNULL(ZZR.ZZR_LOTE, ''))					AS ZZR_LOTE,		
			RTRIM(ISNULL(ZZR.ZZR_ENDER, ''))				AS ZZR_ENDER,		
			ISNULL(ZZR.ZZR_PERDES, 0.00)					AS ZZR_PERDES,
			ISNULL(TMP_DA1.DA1_ZPRCMI, 0.00)                AS DA1_ZPRCMI,
			ISNULL(TMP_DA1.DA1_PRCMAX, 0.00)                AS DA1_PRCMAX,
			ISNULL(TMP_DA1.DA1_PRCVEN, 0.00)                AS DA1_PRCVEN,
			TMP_DA1.DA1_PRECO								AS VALIDACAO_PRECO,	-- CAMPO PARA VALIDAR COM O PREÇO A PAGAR PARA NÃO APARECER PROMOÇÕES COM PREÇO DISCREPANTE OU QUE FICA MAIS CARO DO QUE O CLIENTE JÁ PAGA
			TMP_DA1.DA1_PRECO								AS PRECO_PADRAO_CLIENTE,	-- PREÇO PADRAO DO CLIENTE
			CAST(ROUND(TMP_DA1.DA1_PRECO + IIF(ZZQ.ZZQ_ALAVAN <= 0, 0, TMP_DA1.DA1_PRECO * ZZQ.ZZQ_ALAVAN / 100), 2, 1) AS DECIMAL (12,2)) AS PRECO_RISCADO, -- PREÇO QUE VAI FICAR RISCADO COMO PREÇO ANTERIOR
			
			-- +----------------------------------------------------------------------------------------------------------------------+
			-- | MONTA O PREÇO QUE O CLIENTE VAI PAGAR NA PROMOÇÃO JÁ PEGANDO O PREÇO PADRÃO DO CLIENTE E SE TIVER DESCONTO JÁ APLICA |
			-- +----------------------------------------------------------------------------------------------------------------------+
			CAST(ROUND(
				(CASE
					WHEN ZZR.ZZR_ESCPRC = 'N' THEN ZZR.ZZR_PRCNEG
					WHEN ZZR.ZZR_ESCPRC = 'M' THEN IIF(TMP_DA1.DA1_ZPRCMI IS NULL OR TMP_DA1.DA1_ZPRCMI <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCMI)
					WHEN ZZR.ZZR_ESCPRC = 'S' THEN IIF(TMP_DA1.DA1_PRCVEN IS NULL OR TMP_DA1.DA1_PRCVEN <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCVEN)
					WHEN ZZR.ZZR_ESCPRC = 'X' THEN IIF(TMP_DA1.DA1_PRCMAX IS NULL OR TMP_DA1.DA1_PRCMAX <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCMAX)
					WHEN ZZR.ZZR_ESCPRC = 'E' THEN IIF(TMP_DA1.DA1_ZPRCES IS NULL OR TMP_DA1.DA1_ZPRCES <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCES)
					ELSE TMP_DA1.DA1_PRECO
				END) 
				-
				(CASE
					WHEN ZZR.ZZR_PERDES IS NULL OR ZZR.ZZR_PERDES <= 0 THEN 0
					ELSE(
						(CASE
							WHEN ZZR.ZZR_ESCPRC = 'N' THEN ZZR.ZZR_PRCNEG
							WHEN ZZR.ZZR_ESCPRC = 'M' THEN IIF(TMP_DA1.DA1_ZPRCMI IS NULL OR TMP_DA1.DA1_ZPRCMI <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCMI)
							WHEN ZZR.ZZR_ESCPRC = 'S' THEN IIF(TMP_DA1.DA1_PRCVEN IS NULL OR TMP_DA1.DA1_PRCVEN <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCVEN)
							WHEN ZZR.ZZR_ESCPRC = 'X' THEN IIF(TMP_DA1.DA1_PRCMAX IS NULL OR TMP_DA1.DA1_PRCMAX <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCMAX)
							WHEN ZZR.ZZR_ESCPRC = 'E' THEN IIF(TMP_DA1.DA1_ZPRCES IS NULL OR TMP_DA1.DA1_ZPRCES <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCES)
							ELSE TMP_DA1.DA1_PRECO
						END) 
						*
						(ZZR.ZZR_PERDES / 100)
					)
				END )
			, 2, 1) AS DECIMAL (12,2)) AS PRECO_APAGAR,
			TMP_SB1_FULL.C7_DATPRF                  AS C7_DATPRF,
			-- +-------------------------------------------------------------------+
			-- | MONTA O OBJETO QUANDO TEM BONIFICAÇÃO OU BRINDE ATRELADO A COMPRA |	
			-- +-------------------------------------------------------------------+
			ISNULL(
				(SELECT 
					rTrim(ZZRBON.ZZR_CODIGO)								AS ZZR_CODIGO,
					rTrim(ZZRBON.ZZR_ITEM)									AS ZZR_ITEM,
					rTrim(ZZRBON.ZZR_ITORIG)								AS ZZR_ITORIG,
					rTrim(ZZRBON.ZZR_TPOPER)								AS ZZR_TPOPER,
					rTrim(ZZRBON.ZZR_PRODUT)								AS ZZR_PRODUT,
					rTrim(SB1BON.B1_DESC)									AS B1_DESC,
					rTrim(Z00BON.Z00_FOLDER)								AS Z00_FOLDER,
					CAST(ROUND(ZZRBON.ZZR_QUANT, 2, 1) AS DECIMAL (12,2))	AS ZZR_QUANT,
					ZZRBON.ZZR_MULTBO,
					ZZRBON.ZZR_ESCBON,
					rTrim(ZZRBON.ZZR_ARMAZE)								AS ZZR_ARMAZE,
					rTrim(ZZRBON.ZZR_ENDER)									AS ZZR_ENDER,
					rTrim(ZZRBON.ZZR_LOTE)									AS ZZR_LOTE,		
					ISNULL(ZZRBON.ZZR_PERDES, 0.00)							AS ZZR_PERDES,
					RTRIM(ISNULL(ZZRBON.ZZR_EDIQTD , 'N'))					AS ZZR_EDIQTD,

					CAST(ROUND(
						(CASE
							WHEN ZZRBON.ZZR_ESCPRC IS NULL OR ZZRBON.ZZR_ESCPRC = '' THEN
								(CASE
									WHEN ZZR.ZZR_ESCPRC = 'N' THEN ZZR.ZZR_PRCNEG
									WHEN ZZR.ZZR_ESCPRC = 'M' THEN IIF(TMP_DA1.DA1_ZPRCMI IS NULL OR TMP_DA1.DA1_ZPRCMI <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCMI)
									WHEN ZZR.ZZR_ESCPRC = 'S' THEN IIF(TMP_DA1.DA1_PRCVEN IS NULL OR TMP_DA1.DA1_PRCVEN <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCVEN)
									WHEN ZZR.ZZR_ESCPRC = 'X' THEN IIF(TMP_DA1.DA1_PRCMAX IS NULL OR TMP_DA1.DA1_PRCMAX <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_PRCMAX)
									WHEN ZZR.ZZR_ESCPRC = 'E' THEN IIF(TMP_DA1.DA1_ZPRCES IS NULL OR TMP_DA1.DA1_ZPRCES <= 0, TMP_DA1.DA1_PRECO, TMP_DA1.DA1_ZPRCES)
									ELSE TMP_DA1.DA1_PRECO
								END)
							ELSE
								(CASE
									WHEN ZZRBON.ZZR_ESCPRC = 'N' THEN ZZRBON.ZZR_PRCNEG
									WHEN ZZRBON.ZZR_ESCPRC = 'M' THEN IIF(DA1BON.DA1_ZPRCMI IS NULL OR DA1BON.DA1_ZPRCMI <= 0, TMP_DA1.DA1_PRECO, DA1BON.DA1_ZPRCMI)
									WHEN ZZRBON.ZZR_ESCPRC = 'S' THEN IIF(DA1BON.DA1_PRCVEN IS NULL OR DA1BON.DA1_PRCVEN <= 0, TMP_DA1.DA1_PRECO, DA1BON.DA1_PRCVEN)
									WHEN ZZRBON.ZZR_ESCPRC = 'X' THEN IIF(DA1BON.DA1_PRCMAX IS NULL OR DA1BON.DA1_PRCMAX <= 0, TMP_DA1.DA1_PRECO, DA1BON.DA1_PRCMAX)
									WHEN ZZRBON.ZZR_ESCPRC = 'E' THEN IIF(DA1BON.DA1_ZPRCES IS NULL OR DA1BON.DA1_ZPRCES <= 0, TMP_DA1.DA1_PRECO, DA1BON.DA1_ZPRCES)
									ELSE TMP_DA1.DA1_PRECO
								END)
						END), 2, 1) AS DECIMAL (12,2)) AS PRECO_APAGAR

				FROM ZZR010 ZZRBON WITH (NOLOCK)

					INNER JOIN SB1010 SB1BON WITH (NOLOCK) ON
							SB1BON.D_E_L_E_T_	= ''
						AND SB1BON.B1_FILIAL	= ''
						AND SB1BON.B1_COD		= ZZRBON.ZZR_PRODUT

					LEFT JOIN DA1010 DA1BON WITH (NOLOCK) ON 
							DA1BON.D_E_L_E_T_ = ''
						AND DA1BON.DA1_FILIAL = @FILIAL_DA1
						AND DA1BON.DA1_ATIVO  = '1'
						AND DA1BON.DA1_CODTAB = TMP_SA1.A1_TABELA
						AND DA1BON.DA1_CODPRO = SB1BON.B1_COD
						AND EXISTS (
							SELECT TOP 1 DA0BON.DA0_CODTAB 
							FROM DA0010 DA0BON WITH (NOLOCK)
							WHERE	DA0BON.D_E_L_E_T_ = ''
								AND DA0BON.DA0_FILIAL = DA1BON.DA1_FILIAL
								AND DA0BON.DA0_CODTAB = DA1BON.DA1_CODTAB
								AND DA0BON.DA0_ATIVO  = '1'
						)		

					LEFT JOIN Z00010 Z00BON WITH (NOLOCK) ON
							Z00BON.D_E_L_E_T_ = ''
						AND Z00BON.Z00_FILIAL = ''
						AND Z00BON.Z00_CODIGO = SB1BON.B1_ZMARCA

				WHERE	ZZRBON.D_E_L_E_T_  = ''
					AND ZZRBON.ZZR_FILIAL  = ZZR.ZZR_FILIAL 
					AND ZZRBON.ZZR_CODIGO  = ZZR.ZZR_CODIGO
					AND ZZRBON.ZZR_ITORIG  = ZZR.ZZR_ITEM
					AND ZZRBON.ZZR_TPOPER  != '01'			
					AND ZZR.ZZR_STATUS		= '1'
				ORDER BY ZZRBON.ZZR_FILIAL, ZZRBON.ZZR_CODIGO, ZZRBON.ZZR_ITEM
				FOR JSON AUTO, INCLUDE_NULL_VALUES 
				),
			'[]') AS BONIFICACAO_OBJ,
			rTrim(IsNull(TMP_ZK2.ZK2_FILIAL, ''))	AS ZK2_FILIAL,
			rTrim(IsNull(TMP_ZK2.ZK2_IDAPP, ''))	AS ZK2_IDAPP,
			rTrim(IsNull(TMP_ZK2.ZK2_ITEAPP, ''))	AS ZK2_ITEAPP,
			rTrim(IsNull(TMP_ZK2.ZK2_COD, ''))		AS ZK2_COD,
			IsNull(TMP_ZK2.ZK2_QUANT, 0)			AS ZK2_QUANT,
			rTrim(IsNull(TMP_ZK2.ZK2_CODNEG, ''))	AS ZK2_CODNEG,
			rTrim(IsNull(TMP_ZK2.ZK2_ITNEGO, ''))	AS ZK2_ITNEGO,
			IsNull(TMP_ZK2.ZK2RECNO, 0)				AS ZK2RECNO,
			IsNull(TMP_ZK2.ZK1RECNO, 0)				AS ZK1RECNO,
			'N'										AS EXISTS_PROMOTION,
			ISNULL(ZZR.R_E_C_N_O_, 0)				AS ZZR_RECNO,
			TMP_SB1_FULL.PRODUCT_CATEGORIES_OBJECT  AS PRODUCT_CATEGORIES_OBJECT

		INTO #TEMP_PROMOTION_FULL

		FROM #TEMP_SB1_FULL TMP_SB1_FULL
	
			LEFT JOIN #TEMP_DA1 TMP_DA1 ON
					TMP_DA1.DA1_CODPRO	= TMP_SB1_FULL.B1_COD
		
			INNER JOIN ZZQ010 ZZQ WITH (NOLOCK) ON
					ZZQ.D_E_L_E_T_ = ''
				AND ZZQ.ZZQ_FILIAL = @FILIAL_ZZQ
				AND ZZQ.ZZQ_TIPO   = 'P'	
				AND ZZQ.ZZQ_STATUS = '1'
				AND ZZQ.ZZQ_DTINI  <= FORMAT(getdate(), 'yyyyMMdd')
				AND ZZQ.ZZQ_DTFIN  >= FORMAT(getdate(), 'yyyyMMdd')	
				AND (	@PlaceUse = ''
					OR EXISTS(
						SELECT TOP 1 LOC.value
						FROM STRING_SPLIT(ZZQ.ZZQ_LOCUSO, ',') LOC
						WHERE	LOC.value != ''
							AND LOC.value IN (
								SELECT PAR.value FROM STRING_SPLIT(rTrim(@PlaceUse), '|') PAR
							)
					)
				)		

			INNER JOIN ZZR010 ZZR WITH (NOLOCK) ON
					ZZR.D_E_L_E_T_ = ''
				AND ZZR.ZZR_FILIAL = ZZQ.ZZQ_FILIAL 
				AND ZZR.ZZR_CODIGO = ZZQ.ZZQ_CODIGO
				AND ZZR.ZZR_PRODUT = TMP_SB1_FULL.B1_COD
				AND ZZR.ZZR_TPOPER = '01'
				AND ZZR.ZZR_STATUS = '1'

			LEFT JOIN #TEMP_ZK2 TMP_ZK2 ON
					TMP_ZK2.ZK2_COD		= ZZR.ZZR_PRODUT
				AND TMP_ZK2.ZK2_CODNEG	= ZZR.ZZR_CODIGO
				AND TMP_ZK2.ZK2_ITNEGO	= ZZR.ZZR_ITEM
				AND TMP_ZK2.ZK2_ISNEG  != 'S'
	
			CROSS JOIN #TEMP_SA1 TMP_SA1

		WHERE
			(
				-- SE FOR DO TELEVENDAS PERMITE ITENS SEM TABELA DE PRECO / PRECO ZERADO
				@ORIGN = 'KFGPEDVEN' 
				OR TMP_DA1.DA1_PRECO > 0
			)
			AND (	
				NOT EXISTS (
					SELECT TOP 1 ZZS.ZZS_CODIGO
					FROM ZZS010 ZZS WITH (NOLOCK) 	
					WHERE	ZZS.D_E_L_E_T_ = ''
						AND ZZS.ZZS_FILIAL = ZZR.ZZR_FILIAL
						AND ZZS.ZZS_CODIGO = ZZR.ZZR_CODIGO
						AND ZZS.ZZS_TIPO   = '1'
						AND ZZS.ZZS_MARCA  = '' 
						AND ZZS.ZZS_FORCOD = '' 
						AND ZZS.ZZS_FORLOJ = ''
				)
				OR EXISTS(
					SELECT TOP 1 ZZS.ZZS_CODIGO
					FROM ZZS010 ZZS WITH (NOLOCK) 
					WHERE	ZZS.D_E_L_E_T_ = ''
						AND ZZS.ZZS_FILIAL = ZZQ.ZZQ_FILIAL
						AND ZZS.ZZS_CODIGO = ZZQ.ZZQ_CODIGO
						AND ZZS.ZZS_TIPO   = '1'
						AND(  (	ZZS.ZZS_SETOR  != '' AND ZZS.ZZS_SETOR		 = TMP_SA1.ZZ8_SETOR)
							OR( ZZS.ZZS_DISTRI != '' AND ZZS.ZZS_DISTRI		 = TMP_SA1.ZZ8_SETSUP)
							OR(	ZZS.ZZS_CLICOD != '' AND ZZS.ZZS_CLILOJ		!= '' AND ZZS.ZZS_CLICOD = TMP_SA1.A1_COD AND ZZS.ZZS_CLILOJ = TMP_SA1.A1_LOJA)
							OR(	ZZS.ZZS_TPCLIE != '' AND ZZS.ZZS_TPCLIE		 = TMP_SA1.A1_TIPO)
							OR(	ZZS.ZZS_GRPCLI != '' AND ZZS.ZZS_GRPCLI		 = TMP_SA1.A1_ZGRPCLI)
							OR(	ZZS.ZZS_GRPTRI != '' AND ZZS.ZZS_GRPTRI		 = TMP_SA1.A1_GRPTRIB)
							OR( ZZS.ZZS_GRPVEN != '' AND ZZS.ZZS_GRPVEN		 = TMP_SA1.A1_GRPVEN)
							OR( ZZS.ZZS_REGIAO != '' AND ZZS.ZZS_REGIAO		 = TMP_SA1.CC2_ZREGIA) -- REGIAO
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_CODMUN		 = '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST) -- ESTADO
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_MESORE		!= '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_CODMUN = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_MESORE = TMP_SA1.CC2_ZMESRE) -- MESOR
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_MICRRE		!= '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_CODMUN = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_MICRRE = TMP_SA1.CC2_ZMICRE) -- MICROREGIAO
							OR( ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_CODMUN		!= '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_CODMUN = TMP_SA1.A1_COD_MUN) -- CIDADE
							OR( ZZS.ZZS_TELEVE != '' AND rTRim(@UserCode)	!= '' AND ZZS.ZZS_TELEVE IN (SELECT value FROM STRING_SPLIT(rTrim(@UserCode), '|')))
							OR( ZZS.ZZS_CNDPAG != '' AND (ZZS.ZZS_CNDPAG = TMP_SA1.A1_COND OR (@PaymentConditionCode != '' AND ZZS.ZZS_CNDPAG IN (SELECT value FROM STRING_SPLIT(rTrim(@PaymentConditionCode), '|'))))) 
						)
				)
			)
			AND NOT EXISTS (
					SELECT TOP 1 ZZS.ZZS_CODIGO
					FROM ZZS010 ZZS WITH (NOLOCK) 
					WHERE	ZZS.D_E_L_E_T_ = ''
						AND ZZS.ZZS_FILIAL = ZZQ.ZZQ_FILIAL
						AND ZZS.ZZS_CODIGO = ZZQ.ZZQ_CODIGO
						AND ZZS.ZZS_TIPO   = '2'
						AND(  (	ZZS.ZZS_SETOR  != '' AND ZZS.ZZS_SETOR	 = TMP_SA1.ZZ8_SETOR)
							OR( ZZS.ZZS_DISTRI != '' AND ZZS.ZZS_DISTRI  = TMP_SA1.ZZ8_SETSUP)
							OR(	ZZS.ZZS_CLICOD != '' AND ZZS.ZZS_CLILOJ	!= '' AND ZZS.ZZS_CLICOD = TMP_SA1.A1_COD AND ZZS.ZZS_CLILOJ = TMP_SA1.A1_LOJA)
							OR(	ZZS.ZZS_TPCLIE != '' AND ZZS.ZZS_TPCLIE	 = TMP_SA1.A1_TIPO)
							OR(	ZZS.ZZS_GRPCLI != '' AND ZZS.ZZS_GRPCLI	 = TMP_SA1.A1_ZGRPCLI)
							OR(	ZZS.ZZS_GRPTRI != '' AND ZZS.ZZS_GRPTRI	 = TMP_SA1.A1_GRPTRIB)
							OR( ZZS.ZZS_GRPVEN != '' AND ZZS.ZZS_GRPVEN  = TMP_SA1.A1_GRPVEN)
							OR( ZZS.ZZS_REGIAO != '' AND ZZS.ZZS_REGIAO  = TMP_SA1.CC2_ZREGIA) -- REGIAO
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_CODMUN  = '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST) -- ESTADO
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_MESORE != '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_CODMUN = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_MESORE = TMP_SA1.CC2_ZMESRE) -- MESOR
							OR(	ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_MICRRE != '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_CODMUN = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_MICRRE = TMP_SA1.CC2_ZMICRE) -- MICROREGIAO
							OR( ZZS.ZZS_ESTADO != '' AND ZZS.ZZS_CODMUN != '' AND ZZS.ZZS_MESORE = '' AND ZZS.ZZS_MICRRE = '' AND ZZS.ZZS_ESTADO = TMP_SA1.A1_EST AND ZZS.ZZS_CODMUN = TMP_SA1.A1_COD_MUN) -- CIDADE
							OR( ZZS.ZZS_TELEVE != '' AND rTRim(@UserCode) != '' AND ZZS.ZZS_TELEVE IN (SELECT value FROM STRING_SPLIT(rTrim(@UserCode), '|')))
							OR( ZZS.ZZS_CNDPAG != '' AND (ZZS.ZZS_CNDPAG = TMP_SA1.A1_COND OR (@PaymentConditionCode != '' AND ZZS.ZZS_CNDPAG IN (SELECT value FROM STRING_SPLIT(rTrim(@PaymentConditionCode), '|'))))) 
						)
			) 

		-- +----------------------------------------------------------------------------------------------------------------------------+
		-- | CONVERTE PARA A TEMP FINAL, FOI CRIADO UMA TEMP ANTES PARA PODER FILTRAR OS RESULTAS ANTES DE IR PARA AS VALIDAÇÕES FINAIS |
		-- +----------------------------------------------------------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_PROMOTION') IS NOT NULL
			DROP TABLE #TEMP_PROMOTION 

		SELECT TMP_PROMOTION_FULL.*
		INTO #TEMP_PROMOTION
		FROM #TEMP_PROMOTION_FULL TMP_PROMOTION_FULL 			
		WHERE EXISTS(SELECT TOP 1 TMP_SB1.B1_COD FROM #TEMP_SB1 TMP_SB1 WHERE TMP_SB1.B1_COD = TMP_PROMOTION_FULL.B1_COD)
			AND (	rTrim(@PromotionCode) = ''
				OR(@PromotionItem  = ''	AND TMP_PROMOTION_FULL.ZZQ_CODIGO IN (SELECT value FROM STRING_SPLIT(rTrim(@PromotionCode), '|'))) 
				OR(@PromotionItem != '' AND TMP_PROMOTION_FULL.ZZQ_CODIGO = @PromotionCode)				
			)
			AND (@PromotionItem = '' OR (rTrim(@PromotionCode) != '' AND TMP_PROMOTION_FULL.ZZR_ITEM = @PromotionItem))
			-- +-----------------------------------------------------------------------------------------+
			-- | VALIDA SE O PREÇO NÃO É FURADO PARA NÃO APARECER PROMOÇÃO COM PREÇO QUE NÃO FAZ SENTIDO |
			-- +-----------------------------------------------------------------------------------------+
			AND ((TMP_PROMOTION_FULL.PRECO_RISCADO > TMP_PROMOTION_FULL.PRECO_APAGAR AND TMP_PROMOTION_FULL.VALIDACAO_PRECO > TMP_PROMOTION_FULL.PRECO_APAGAR) OR(TMP_PROMOTION_FULL.BONIFICACAO_OBJ IS NOT NULL AND TMP_PROMOTION_FULL.BONIFICACAO_OBJ != '' AND TMP_PROMOTION_FULL.BONIFICACAO_OBJ != '[]'));
		

		SET @PromotionRowResult = ISNULL((SELECT COUNT(TMP_PROMOTION.B1_COD) FROM #TEMP_PROMOTION TMP_PROMOTION), 0); --CONTA PARA VER QUANTAS PROMOÇÕES ACHOU

		-- +---------------------------------------------------------------------------------------------------------+
		-- | ATUALIZA O PERCENTUAL DE DESCONTO QUANDO O MESMO NÃO FOI INFORMADO, PARA ABASTERCER A TAG OFF DO PORTAL |
		-- +---------------------------------------------------------------------------------------------------------+
		UPDATE #TEMP_PROMOTION 
		SET #TEMP_PROMOTION.ZZR_PERDES = CAST(ROUND(100 - ((#TEMP_PROMOTION.PRECO_APAGAR / #TEMP_PROMOTION.PRECO_RISCADO)*100), 2, 1) AS DECIMAL (6,0))
		WHERE	#TEMP_PROMOTION.ZZR_PERDES	   <= 0
			AND #TEMP_PROMOTION.PRECO_RISCADO	> 0
			AND #TEMP_PROMOTION.PRECO_RISCADO	> #TEMP_PROMOTION.PRECO_APAGAR;
			
		-- +----------------------------------------------------------------------+
		-- | ATUALIZA OS PRODUTOS SEM PROMOÇÃO QUE POSSUI UMA PROMOÇÃO CADASTRADA |
		-- +----------------------------------------------------------------------+
		UPDATE TMP_DEFAULT 
		SET EXISTS_PROMOTION = 'S' 
		FROM #TEMP_DEFAULT TMP_DEFAULT
		WHERE EXISTS(
			SELECT TOP 1 TMP_PROMOTION.B1_COD 
			FROM #TEMP_PROMOTION TMP_PROMOTION 
			WHERE TMP_PROMOTION.B1_COD = TMP_DEFAULT.B1_COD
		);

		-- +---------------------------------------------------------------------------------+
		-- | ATUALIZA SE TEM PROMOÇÕES ALÉM DA ATUAL OU SEJA SE O PRODUTO TEM MAIS PROMOÇÕES |
		-- +---------------------------------------------------------------------------------+
		UPDATE TMP_PROMOTION 
		SET EXISTS_PROMOTION = 'S' 
		FROM #TEMP_PROMOTION TMP_PROMOTION
		WHERE EXISTS(
			SELECT TOP 1 TMP_PROM02.B1_COD 
			FROM #TEMP_PROMOTION TMP_PROM02 
			WHERE	TMP_PROM02.B1_COD = TMP_PROMOTION.B1_COD
				AND TMP_PROM02.ZZR_RECNO != TMP_PROMOTION.ZZR_RECNO
		);


	END;
	
	-- +-------------------------------------------------------------------------------------------------------+
	-- | QUANDO SOLICITA ALGUMAS INFORMAÇÕES PRINCIPAIS COMO UTLIMAS COMPRAS, DESTAQUES, PRODUTOS NOVOS ETC... |
	-- +-------------------------------------------------------------------------------------------------------+
	IF @MainQueryExecute = 1
	BEGIN;

		-- +-----------------------------------+----------------------------------------------------------------------------+
		-- | ÚLTIMAS COMPRAS [VOCÊ VAI GOSTAR] | PRODUTOS QUE JÁ FORAM COMPRADOS PELO CLIETE E ESTÁ NOS PARÂMETROS CORRETOS |
		-- +-----------------------------------+----------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_LAST_PURCHASE') IS NOT NULL DROP TABLE #TEMP_LAST_PURCHASE

		SELECT TOP (@SelectTopItensLatestPurchases)	TMP_DEF.*
		INTO #TEMP_LAST_PURCHASE
		FROM  #TEMP_DEFAULT TMP_DEF
		WHERE TMP_DEF.D2_DTULTCP != ''
		ORDER BY TMP_DEF.D2_DTULTCP DESC, TMP_DEF.B1_DESC;

		SET @LastPruchaseRowResult = ISNULL((SELECT COUNT(TMP_LAST_PURCHASE.B1_COD) FROM #TEMP_LAST_PURCHASE TMP_LAST_PURCHASE), 0); -- CONTAR QUANTOS PRODUTOS ENTRARAM NAS ÚLTIMAS COMPRAS

		-- +---------------------------+-------------------------------------------------------------------------------------------------------------------------+
		-- | MAIS VENDIDOS [DESTAQUES] | MAIS COMPRADOS NA EMPRESA TODA PORÉM SEM OS PRODUTOS QUE JÁ APARECERAM NAS ÚLTIMAS COMPRAS DO CLIENTE PARA NÃO DUPLICAR |
		-- +---------------------------+-------------------------------------------------------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_BESTSELLERS') IS NOT NULL DROP TABLE #TEMP_BESTSELLERS

		SELECT TOP (@SelectTopItensBestSellers)	TMP_DEF.*
		INTO #TEMP_BESTSELLERS
		FROM  #TEMP_DEFAULT TMP_DEF
		ORDER BY TMP_DEF.B1_ZQTDVEN DESC, TMP_DEF.B1_DESC;

		SET @BestsellersRowResult = ISNULL((SELECT COUNT(TMP_BESTSELLERS.B1_COD) FROM #TEMP_BESTSELLERS TMP_BESTSELLERS), 0); -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS MAIS VENDIDOS



		-- +----------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
		-- | PRODUTOS NOVOS [NOVIDADES] | PRODUTOS QUE SÃO NOVOS DENTRO DA EMRPESA E QUE ESTÁ DEFINIDO NOS PARÂMETROS CONFIGURADOS PORÉM SEM OS PRODUTOS QUE JÁ APARECERAM NAS ÚLTIMAS COMPRAS E MAIS VENDIDOS |
		-- +----------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_NEW_PRODUCT') IS NOT NULL DROP TABLE #TEMP_NEW_PRODUCT

		SELECT TOP (@SelectTopItensNewProducts)	TMP_DEF.*
		INTO #TEMP_NEW_PRODUCT
		FROM  #TEMP_DEFAULT TMP_DEF
		WHERE TMP_DEF.B1_ISNEW = 'S' 
		ORDER BY TMP_DEF.B1_ZPRDNOV DESC, TMP_DEF.B1_DESC;

		SET @NewProductsRowResult = ISNULL((SELECT COUNT(TMP_NEW_PRODUCT.B1_COD) FROM #TEMP_NEW_PRODUCT TMP_NEW_PRODUCT), 0); -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS NOVOS

		-- +--------------------------------------------------------+-------------------------------------------------------------------------------+
		-- | PRODUTOS DA KFG [PRODUTOS QUE SÃO FABRICADOS PELA KFG] | PRODUTOS QUE A KFG PRODUZ, ESTÁ SENDO FILTRADO ADA, VILLA RICA E MARIA BONITA |
		-- +--------------------------------------------------------+-------------------------------------------------------------------------------+
		IF OBJECT_ID('tempdb..#TEMP_KFG_PRODUCTS') IS NOT NULL DROP TABLE #TEMP_KFG_PRODUCTS

		SELECT TMP_KFG.*
		INTO #TEMP_KFG_PRODUCTS
		FROM (

			-- +---------------------------+
			-- | MARCA CÓDIGO:000015 - ADA |
			-- +---------------------------+
			SELECT TOP (@SelectTopItensKFGProducts) TMP_DEF.*			
			FROM  #TEMP_DEFAULT TMP_DEF
			WHERE TMP_DEF.B1_ZMARCA = '000015'
			
			UNION ALL 

			-- +-------------------------------+
			-- | MARCA CÓDIGO:000472 - COFFEON |
			-- +-------------------------------+ 
			SELECT TOP (@SelectTopItensKFGProducts) TMP_DEF.*
			FROM  #TEMP_DEFAULT TMP_DEF
			WHERE TMP_DEF.B1_ZMARCA = '000472'  
			
			UNION ALL 
			
			-- +----------------------------------+
			-- | MARCA CÓDIGO:000271 - VILLA RICA |
			-- +----------------------------------+ 
			SELECT TOP (@SelectTopItensKFGProducts) TMP_DEF.*
			FROM  #TEMP_DEFAULT TMP_DEF
			WHERE TMP_DEF.B1_ZMARCA = '000271'  
			
			UNION ALL 

			-- +------------------------------------+
			-- | MARCA CÓDIGO:000376 - MARIA BONITA |
			-- +------------------------------------+ 
			SELECT TOP (@SelectTopItensKFGProducts) TMP_DEF.*
			FROM  #TEMP_DEFAULT TMP_DEF
			WHERE TMP_DEF.B1_ZMARCA = '000376'
			ORDER BY TMP_DEF.B1_ZQTDVEN DESC, TMP_DEF.B1_DESC ASC
			
			UNION ALL 
			
			-- +------------------------------------+
			-- | MARCA CÓDIGO:000374 - ORGANICUM    |
			-- +------------------------------------+ 
			SELECT TOP (@SelectTopItensKFGProducts) TMP_DEF.*
			FROM  #TEMP_DEFAULT TMP_DEF
			WHERE TMP_DEF.B1_ZMARCA = '000374'
			ORDER BY TMP_DEF.B1_ZQTDVEN DESC, TMP_DEF.B1_DESC ASC

		) AS TMP_KFG;

		SET @KFGAdaRowResult			= ISNULL((SELECT COUNT(TMP_KFG_PRODUCTS.B1_COD) FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS WHERE TMP_KFG_PRODUCTS.B1_ZMARCA = '000015'), 0);  -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS DA ADA
		SET @KFGVillaRicaRowResult		= ISNULL((SELECT COUNT(TMP_KFG_PRODUCTS.B1_COD) FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS WHERE TMP_KFG_PRODUCTS.B1_ZMARCA = '000271'), 0);  -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS DA VILLA RICA
		SET @KFGMariaBonitaRowResult	= ISNULL((SELECT COUNT(TMP_KFG_PRODUCTS.B1_COD) FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS WHERE TMP_KFG_PRODUCTS.B1_ZMARCA = '000376'), 0);  -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS DA MARIA BONITA
		SET @KFGOrganicumRowResult	    = ISNULL((SELECT COUNT(TMP_KFG_PRODUCTS.B1_COD) FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS WHERE TMP_KFG_PRODUCTS.B1_ZMARCA = '000374'), 0);  -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS DA ORGANICUM
		SET @KFGCoffeonRowResult	    = ISNULL((SELECT COUNT(TMP_KFG_PRODUCTS.B1_COD) FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS WHERE TMP_KFG_PRODUCTS.B1_ZMARCA = '000472'), 0);  -- CONTAR QUANTOS PRODUTOS ENTRARAM NOS PRODUTOS DA COFFEON
		
		SET @KFGProductsRowResult		= (@KFGAdaRowResult + @KFGVillaRicaRowResult + @KFGMariaBonitaRowResult + @KFGOrganicumRowResult + @KFGCoffeonRowResult); -- SOMA O TOTAL DOS ITENS ACIMA QUE SÃO PRODUZIDOS PELA KFG

		
	END;


	-- +-----------------------------------------------------------------------------------------------------------------------------------------------------------------+
	-- | BUSCA OS PRODUTOS QUE EXISTEM NA TABELA QUE TEM OS PRODUTOS FILTRADOS, PARA PEGAR OS PRODUTOS SEM OS VALORES DE PROMOÇÕES OU SEJA O PREÇO QUE O CLIENTE UTILIZA |
	-- +-----------------------------------------------------------------------------------------------------------------------------------------------------------------+
	IF @ProductQueryExecute = 1
	BEGIN;
					
		IF OBJECT_ID('tempdb..#TEMP_PRODUCT') IS NOT NULL DROP TABLE #TEMP_PRODUCT 

		SELECT TMP_DEF.*	
		INTO #TEMP_PRODUCT		
		FROM  #TEMP_DEFAULT TMP_DEF
		WHERE @PromotionCode = ''
			AND EXISTS(SELECT TOP 1 TMP_SB1.B1_COD FROM #TEMP_SB1 TMP_SB1 WHERE TMP_SB1.B1_COD = TMP_DEF.B1_COD) -- SOMENTE OS PRODUTOS QUE ESTÃO DENTRO DA TABELA AONDE OS FILTROS ESTÃO APLICADOS
		ORDER BY TMP_DEF.B1_COD

		SET @ProductRowResult = ISNULL((SELECT COUNT(TMP_PRODUCT.B1_COD) FROM #TEMP_PRODUCT TMP_PRODUCT), 0); -- CONTAR QUANTOS PRODUTOS A CONSULTA RETORNOU

	END;

	-- +------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	-- | MONTA OS OBJETOS DE JSON DA LISTA DE MARCAS, CATEGORIAS E PROMOÇÕES QUANDO O PARÂMETRO PASSADO FOI PROMOÇÃO E PRODUTOS E PELO MENOS ALGUM DELES VOLTOU RESULTADO |
	-- +------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	IF (@ProductQueryExecute = 1 OR @PromotionQueryExecute = 1) AND (@ProductRowResult > 0 OR @PromotionRowResult > 0)
	BEGIN;

		-- +-----------------------------------------------+
		-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'ALL' |
		-- +-----------------------------------------------+
		IF @ProductQueryExecute = 1 AND @PromotionQueryExecute = 1
		BEGIN;

			-- +--------------------+
			-- | MARCAS DE PRODUTOS |
			-- +--------------------+
			SET @BrandListObject = rTrim(IsNull((
				SELECT 
					rTrim(BRANDS.BRAND_CODE)	AS CODE,
					rTrim(BRANDS.BRAND_NAME)	AS NAME, 
					Sum(BRANDS.PRODUCT_COUNTER) AS COUNT
				FROM (
						SELECT	TMP_DEFAULT.B1_ZMARCA		AS BRAND_CODE,
								TMP_DEFAULT.Z00_DESCLI		AS BRAND_NAME,
								Count(TMP_DEFAULT.B1_COD)	AS PRODUCT_COUNTER
						FROM #TEMP_DEFAULT TMP_DEFAULT
						WHERE TMP_DEFAULT.B1_ZMARCA != '' 
						GROUP BY TMP_DEFAULT.B1_ZMARCA, TMP_DEFAULT.Z00_DESCLI

						UNION ALL

						SELECT	TMP_PROMOTION_FULL.B1_ZMARCA		AS BRAND_CODE,
								TMP_PROMOTION_FULL.Z00_DESCLI		AS BRAND_NAME,
								Count(TMP_PROMOTION_FULL.B1_COD)	AS PRODUCT_COUNTER
						FROM #TEMP_PROMOTION_FULL TMP_PROMOTION_FULL
						WHERE	TMP_PROMOTION_FULL.B1_ZMARCA != ''							
						GROUP BY TMP_PROMOTION_FULL.B1_ZMARCA, TMP_PROMOTION_FULL.Z00_DESCLI

					) AS BRANDS
				GROUP BY BRANDS.BRAND_CODE, BRANDS.BRAND_NAME				
				ORDER BY
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Sum(BRANDS.PRODUCT_COUNTER)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Sum(BRANDS.PRODUCT_COUNTER)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN BRANDS.BRAND_CODE				ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN BRANDS.BRAND_CODE				ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN BRANDS.BRAND_NAME				ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN BRANDS.BRAND_NAME				ELSE NULL END) DESC

				FOR JSON AUTO, INCLUDE_NULL_VALUES  
			),'[]'));
			

			-- +-------------------------+
			-- | CATERGORIAS DE PRODUTOS |
			-- +-------------------------+
			SET @CategoryListObject	= rTrim(IsNull((
				SELECT 
					rTrim(CATEGORY.CATEGORY_CODE) AS CODE,
					rTrim(CATEGORY.CATEGORY_NAME) AS NAME, 
					Sum(CATEGORY.PRODUCT_COUNTER) AS COUNT
				FROM (
						SELECT	TMP_DEFAULT.B1_GRUPO		AS CATEGORY_CODE,
								TMP_DEFAULT.BM_ZDESCLI		AS CATEGORY_NAME,
								Count(TMP_DEFAULT.B1_COD)	AS PRODUCT_COUNTER
						FROM #TEMP_DEFAULT TMP_DEFAULT
						WHERE TMP_DEFAULT.B1_GRUPO != '' 
						GROUP BY TMP_DEFAULT.B1_GRUPO, TMP_DEFAULT.BM_ZDESCLI

						UNION ALL

						SELECT	TMP_PROMOTION_FULL.B1_GRUPO			AS CATEGORY_CODE,
								TMP_PROMOTION_FULL.BM_ZDESCLI		AS CATEGORY_NAME,
								Count(TMP_PROMOTION_FULL.B1_COD)	AS PRODUCT_COUNTER
						FROM #TEMP_PROMOTION_FULL TMP_PROMOTION_FULL
						WHERE	TMP_PROMOTION_FULL.B1_GRUPO != ''							
						GROUP BY TMP_PROMOTION_FULL.B1_GRUPO, TMP_PROMOTION_FULL.BM_ZDESCLI

					) AS CATEGORY
				GROUP BY CATEGORY.CATEGORY_CODE, CATEGORY.CATEGORY_NAME
				ORDER BY 
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Sum(CATEGORY.PRODUCT_COUNTER)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Sum(CATEGORY.PRODUCT_COUNTER)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN CATEGORY.CATEGORY_CODE			ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN CATEGORY.CATEGORY_CODE			ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN CATEGORY.CATEGORY_NAME			ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN CATEGORY.CATEGORY_NAME			ELSE NULL END) DESC

				FOR JSON AUTO, INCLUDE_NULL_VALUES 
			),'[]'));

		END;
	
		-- +------------------------------------------------------------+
		-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'PRODUCT' OU 'ALL' |
		-- +------------------------------------------------------------+
		IF @ProductQueryExecute = 1 AND @PromotionQueryExecute = 0
		BEGIN;

			-- +--------------------+
			-- | MARCAS DE PRODUTOS |
			-- +--------------------+
			SET @BrandListObject = rTrim(IsNull((
				SELECT	rTrim(TMP_DEFAULT.B1_ZMARCA)	AS CODE,
						rTrim(TMP_DEFAULT.Z00_DESCLI)	AS NAME,
						Count(TMP_DEFAULT.B1_COD)		AS COUNT
				FROM #TEMP_DEFAULT TMP_DEFAULT
				WHERE TMP_DEFAULT.B1_ZMARCA != ''
				GROUP BY TMP_DEFAULT.B1_ZMARCA, TMP_DEFAULT.Z00_DESCLI
				ORDER BY
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Count(TMP_DEFAULT.B1_COD)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Count(TMP_DEFAULT.B1_COD)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN TMP_DEFAULT.B1_ZMARCA		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN TMP_DEFAULT.B1_ZMARCA		ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN TMP_DEFAULT.Z00_DESCLI	ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN TMP_DEFAULT.Z00_DESCLI	ELSE NULL END) DESC

				FOR JSON AUTO, INCLUDE_NULL_VALUES 
			),'[]'));

			
			-- +-------------------------+
			-- | CATERGORIAS DE PRODUTOS |
			-- +-------------------------+
			SET @CategoryListObject	= rTrim(IsNull((
				SELECT	TMP_DEFAULT.B1_GRUPO		AS CODE,
						TMP_DEFAULT.BM_ZDESCLI		AS NAME,
						Count(TMP_DEFAULT.B1_COD)	AS COUNT
				FROM #TEMP_DEFAULT TMP_DEFAULT
				WHERE TMP_DEFAULT.B1_GRUPO != '' 
				GROUP BY TMP_DEFAULT.B1_GRUPO, TMP_DEFAULT.BM_ZDESCLI
				ORDER BY
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Count(TMP_DEFAULT.B1_COD)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Count(TMP_DEFAULT.B1_COD)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN TMP_DEFAULT.B1_GRUPO		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN TMP_DEFAULT.B1_GRUPO		ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN TMP_DEFAULT.BM_ZDESCLI	ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN TMP_DEFAULT.BM_ZDESCLI	ELSE NULL END) DESC

				FOR JSON AUTO, INCLUDE_NULL_VALUES 
			),'[]'));

		END;


		-- +--------------------------------------------------------------+
		-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'PROMOTION' OU 'ALL' |
		-- +--------------------------------------------------------------+
		IF @ProductQueryExecute = 0 AND @PromotionQueryExecute = 1
		BEGIN;

			-- +--------------------+
			-- | MARCAS DE PRODUTOS |
			-- +--------------------+
			SET @BrandListObject = rTrim(IsNull((					
				SELECT	rTrim(TMP_PROMOTION_FULL.B1_ZMARCA)	AS CODE,
						rTrim(TMP_PROMOTION_FULL.Z00_DESCLI)	AS NAME,
						Count(TMP_PROMOTION_FULL.B1_COD)		AS COUNT
				FROM #TEMP_PROMOTION_FULL TMP_PROMOTION_FULL
				WHERE	TMP_PROMOTION_FULL.B1_ZMARCA != ''
				GROUP BY TMP_PROMOTION_FULL.B1_ZMARCA, TMP_PROMOTION_FULL.Z00_DESCLI				
				ORDER BY
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Count(TMP_PROMOTION_FULL.B1_COD)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Count(TMP_PROMOTION_FULL.B1_COD)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN TMP_PROMOTION_FULL.B1_ZMARCA		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN TMP_PROMOTION_FULL.B1_ZMARCA		ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN TMP_PROMOTION_FULL.Z00_DESCLI		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN TMP_PROMOTION_FULL.Z00_DESCLI		ELSE NULL END) DESC

				FOR JSON AUTO, INCLUDE_NULL_VALUES 
			),'[]'));

			-- +-------------------------+
			-- | CATERGORIAS DE PRODUTOS |
			-- +-------------------------+
			SET @CategoryListObject	= '[]';

		END;

		-- +--------------------------------------------------------------+
		-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'PROMOTION' OU 'ALL' |
		-- +--------------------------------------------------------------+
		IF @PromotionQueryExecute = 1
		BEGIN;

			-- +-----------------------+
			-- | PROMOÇÕES DE PRODUTOS |
			-- +-----------------------+
			SET @PromotionListObject = rTrim(IsNull((
				SELECT	rTrim(TMP_PROMOTION_FULL.ZZQ_CODIGO)	AS CODE,
						rTrim(TMP_PROMOTION_FULL.ZZQ_DESCLI)	AS NAME,
						Count(TMP_PROMOTION_FULL.B1_COD)		AS COUNT
				FROM #TEMP_PROMOTION_FULL TMP_PROMOTION_FULL
				WHERE TMP_PROMOTION_FULL.ZZQ_CODIGO != ''
				GROUP BY TMP_PROMOTION_FULL.ZZQ_CODIGO, TMP_PROMOTION_FULL.ZZQ_DESCLI				
				ORDER BY 
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT', 'COUNT ASC')							THEN Count(TMP_PROMOTION_FULL.B1_COD)	ELSE NULL END),			
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('COUNT DESC', NULL, '')						THEN Count(TMP_PROMOTION_FULL.B1_COD)	ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE', 'CODE ASC')							THEN TMP_PROMOTION_FULL.ZZQ_CODIGO		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('CODE DESC')									THEN TMP_PROMOTION_FULL.ZZQ_CODIGO		ELSE NULL END) DESC,
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME', 'NAME ASC', 'COUNT DESC', NULL, '')	THEN TMP_PROMOTION_FULL.ZZQ_DESCLI		ELSE NULL END),
					(CASE WHEN rTrim(Upper(@OrderByFilters)) IN ('NAME DESC')									THEN TMP_PROMOTION_FULL.ZZQ_DESCLI		ELSE NULL END) DESC	

				FOR JSON AUTO, INCLUDE_NULL_VALUES 
			),'[]'));

		END;

	END;


	-- ##########################################################################################
	-- ### +--------------------------------------------------------------------------------+ ###
	-- ### | RETORNO OS DADOS QUE SERÃO MOSTRADOS EM TELA, OU SEJA O RESULTADO DOS FILTROS. | ###
	-- ### +--------------------------------------------------------------------------------+ ###
	-- ##########################################################################################


	-- @QueryResult == 'HOME' TRATATIVA PARA HOME E UNION ALL DE FITROS COM PROMOÇÃO
	IF @MainQueryExecute = 1
	BEGIN;
	
		SELECT 		
			TMP_HOME.*,			
			@ProductRowResult		AS PRODUCT_COUNT,
			@PromotionRowResult		AS PROMOTION_COUNT,
			@BestsellersRowResult	AS BESTSELLERS_COUNT,
			@NewProductsRowResult	AS NEWPRODUCTS_COUNT
		FROM (
			
			-- Mais comprados
			SELECT
				'BESTSELLERS' AS ORIGEM_DESC,
				TMP_BESTSELLERS.*
			FROM #TEMP_BESTSELLERS TMP_BESTSELLERS		

			UNION ALL 

			-- Comprados recentemente
			SELECT 
				'LAST_PURCHASE' AS ORIGEM_DESC,
				TMP_LAST_PURCHASE.* 
			FROM #TEMP_LAST_PURCHASE TMP_LAST_PURCHASE

			UNION ALL

			SELECT TOP (@SelectTopItensPromotions) 
				'PROMOTIONS' AS ORIGEM_DESC,
				TMP_PROMOTION.*
			FROM #TEMP_PROMOTION TMP_PROMOTION	
			ORDER BY TMP_PROMOTION.B1_ZQTDVEN DESC, TMP_PROMOTION.B1_DESC
			
			UNION ALL 

			SELECT TOP (@SelectTopItensPromotionsBanner) 
				'PROMOTION_WITH_BANNER' AS ORIGEM_DESC,
				TMP_PROMOTION.*
			FROM #TEMP_PROMOTION TMP_PROMOTION
			WHERE 	TMP_PROMOTION.ZZR_IMGBAN != '' 
				OR (TMP_PROMOTION.ZZQ_IMGBAN != '' AND TMP_PROMOTION.ZZR_ITEM = (SELECT MAX(TMP_PROMO_BANNER.ZZR_ITEM) FROM #TEMP_PROMOTION TMP_PROMO_BANNER WHERE TMP_PROMO_BANNER.ZZQ_CODIGO = TMP_PROMOTION.ZZQ_CODIGO AND TMP_PROMO_BANNER.ZZQ_IMGBAN =  TMP_PROMOTION.ZZQ_IMGBAN	)) 
			ORDER BY TMP_PROMOTION.B1_ZQTDVEN DESC, TMP_PROMOTION.B1_DESC
			
			UNION ALL 
			
			SELECT 
				'NEW_PRODUCT' AS ORIGEM_DESC,
				TMP_NEW_PRODUCT.*
			FROM #TEMP_NEW_PRODUCT TMP_NEW_PRODUCT				
			WHERE TMP_NEW_PRODUCT.B1_QATU > 0 	
			
			UNION ALL 
			
			SELECT  
				'KFG_PRODUCT_' + Cast(Cast(TMP_KFG_PRODUCTS.B1_ZMARCA AS INT) AS VARCHAR) AS ORIGEM_DESC,
				TMP_KFG_PRODUCTS.*
			FROM #TEMP_KFG_PRODUCTS TMP_KFG_PRODUCTS
				
		) AS TMP_HOME
	
		ORDER BY TMP_HOME.ORIGEM_DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE', 'CODE ASC')										THEN TMP_HOME.B1_COD		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE DESC')												THEN TMP_HOME.B1_COD		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION', 'DESCRIPTION ASC')						THEN TMP_HOME.B1_DESC		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION DESC')										THEN TMP_HOME.B1_DESC		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE', 'PRICE ASC')									THEN TMP_HOME.PRECO_APAGAR	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE DESC')											THEN TMP_HOME.PRECO_APAGAR	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE', 'MIN_PRICE ASC')							THEN TMP_HOME.DA1_ZPRCMI	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE DESC')										THEN TMP_HOME.DA1_ZPRCMI	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE', 'SUG_PRICE ASC')							THEN TMP_HOME.DA1_PRCVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE DESC')										THEN TMP_HOME.DA1_PRCVEN	ELSE NULL END) DESC,

			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK', 'STOCK ASC')									THEN TMP_HOME.B1_QATU		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK DESC')											THEN TMP_HOME.B1_QATU		ELSE NULL END) DESC,
			
            (CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES', 'LAUNCHES ASC')								THEN TMP_HOME.B1_ZPRDNOV	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES DESC')											THEN TMP_HOME.B1_ZPRDNOV	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES', 'PURCHASES ASC')							THEN TMP_HOME.D2_DTULTCP	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES DESC')										THEN TMP_HOME.D2_DTULTCP	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS', 'BESTSELLERS ASC')						THEN TMP_HOME.B1_ZQTDVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS DESC',  NULL, '','PURCHASES DESC')			THEN TMP_HOME.B1_ZQTDVEN	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER', 'PRODUCT_CODE_ORDER ASC')			THEN TMP_HOME.ORDEM_CODIGO	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER DESC')								THEN TMP_HOME.ORDEM_CODIGO	ELSE NULL END) DESC;
			
		RETURN;

	END;

	-- +-----------------------------------------------+
	-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'ALL' |
	-- +-----------------------------------------------+
	IF @ProductQueryExecute = 1 AND @PromotionQueryExecute = 1
	BEGIN;
		SELECT	TMP_PRODUCT_PROMOTION.*,
				@ProductRowResult							AS PRODUCT_COUNT,
				@PromotionRowResult							AS PROMOTION_COUNT,
				(@ProductRowResult + @PromotionRowResult)	AS PRODUCT_PROMOTION_COUNT, 
				@BrandListObject							AS BRAND_LIST_OBJ,
				@CategoryListObject							AS CATEGORY_LIST_OBJ,
				@PromotionListObject						AS PROMOTION_LIST_OBJ
		FROM (
			/*				
			SELECT TMP_PRODUCT.*
			FROM #TEMP_PRODUCT TMP_PRODUCT
	
			UNION ALL

			SELECT TMP_PROMOTION.*
			FROM #TEMP_PROMOTION TMP_PROMOTION
			WHERE @resultPromotion != 'S' 
			*/
			SELECT TMP_PROMOTION.*
			FROM #TEMP_PROMOTION TMP_PROMOTION
			WHERE @resultPromotion != 'S' 
			
			UNION ALL
			
			SELECT TMP_PRODUCT.*
			FROM #TEMP_PRODUCT TMP_PRODUCT
			
			WHERE 
			(
				@QueryResult = 'ORDER'
				OR NOT EXISTS (
					SELECT TMP_PROMOTION.B1_COD 
					FROM #TEMP_PROMOTION TMP_PROMOTION
					WHERE @resultPromotion != 'S' and TMP_PROMOTION.B1_COD = TMP_PRODUCT.B1_COD
				)
			)
		) AS TMP_PRODUCT_PROMOTION
		WHERE
			-- TRATATIVA DO QUERY_RESULT ORDER
			(
					@QueryResult <> 'ORDER'
				OR	EXISTS (
					SELECT TOP 1 
						TEMP_CARRINHO_ATUAL.ZK2_COD 
					FROM #TEMP_CARRINHO_ATUAL TEMP_CARRINHO_ATUAL  WITH (NOLOCK)
					WHERE 
							TEMP_CARRINHO_ATUAL.ZK2_COD     = TMP_PRODUCT_PROMOTION.B1_COD
						AND (
								TEMP_CARRINHO_ATUAL.ZK2_ISNEG   = 'S'
								OR (
									    TEMP_CARRINHO_ATUAL.ZK2_CODNEG  = TMP_PRODUCT_PROMOTION.ZZQ_CODIGO
									AND TEMP_CARRINHO_ATUAL.ZK2_ITNEGO  = TMP_PRODUCT_PROMOTION.ZZR_ITEM
								)
						)
				)
			) 
		
		ORDER BY 
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE', 'CODE ASC')							    THEN TMP_PRODUCT_PROMOTION.B1_COD		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE DESC')									    THEN TMP_PRODUCT_PROMOTION.B1_COD		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION', 'DESCRIPTION ASC', NULL, '')	    THEN TMP_PRODUCT_PROMOTION.B1_DESC		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION DESC')							    THEN TMP_PRODUCT_PROMOTION.B1_DESC		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE', 'PRICE ASC')						    THEN TMP_PRODUCT_PROMOTION.PRECO_APAGAR	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE DESC')								    THEN TMP_PRODUCT_PROMOTION.PRECO_APAGAR	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE', 'MIN_PRICE ASC')					THEN TMP_PRODUCT_PROMOTION.DA1_ZPRCMI	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE DESC')								THEN TMP_PRODUCT_PROMOTION.DA1_ZPRCMI	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE', 'SUG_PRICE ASC')					THEN TMP_PRODUCT_PROMOTION.DA1_PRCVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE DESC')								THEN TMP_PRODUCT_PROMOTION.DA1_PRCVEN	ELSE NULL END) DESC,

			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK', 'STOCK ASC')							THEN TMP_PRODUCT_PROMOTION.B1_QATU		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK DESC')									THEN TMP_PRODUCT_PROMOTION.B1_QATU		ELSE NULL END) DESC,
			
            (CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES', 'LAUNCHES ASC')					    THEN TMP_PRODUCT_PROMOTION.B1_ZPRDNOV	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES DESC')								    THEN TMP_PRODUCT_PROMOTION.B1_ZPRDNOV	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES', 'PURCHASES ASC')				    THEN TMP_PRODUCT_PROMOTION.D2_DTULTCP	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES DESC')							    THEN TMP_PRODUCT_PROMOTION.D2_DTULTCP	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS', 'BESTSELLERS ASC')			    THEN TMP_PRODUCT_PROMOTION.B1_ZQTDVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS DESC','PURCHASES DESC')			    THEN TMP_PRODUCT_PROMOTION.B1_ZQTDVEN	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER', 'PRODUCT_CODE_ORDER ASC')	THEN TMP_PRODUCT_PROMOTION.ORDEM_CODIGO	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER DESC')					    THEN TMP_PRODUCT_PROMOTION.ORDEM_CODIGO	ELSE NULL END) DESC
			
		OFFSET @PageNumber ROWS 
		FETCH NEXT @NumberRowsPerPage ROWS ONLY;

		RETURN;

	END;
	
	-- +---------------------------------------------------+
	-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'PRODUCT' |
	-- +---------------------------------------------------+
	IF @ProductQueryExecute = 1 
	BEGIN;

		SELECT	
			TMP_PRODUCT.*,
			@ProductRowResult							AS PRODUCT_COUNT,
			@PromotionRowResult							AS PROMOTION_COUNT,
			(@ProductRowResult + @PromotionRowResult)	AS PRODUCT_PROMOTION_COUNT, 
			@BrandListObject							AS BRAND_LIST_OBJ,
			@CategoryListObject							AS CATEGORY_LIST_OBJ,
			@PromotionListObject						AS PROMOTION_LIST_OBJ
		FROM #TEMP_PRODUCT TMP_PRODUCT
		ORDER BY 
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE', 'CODE ASC')									THEN TMP_PRODUCT.B1_COD			ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE DESC')											THEN TMP_PRODUCT.B1_COD			ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION', 'DESCRIPTION ASC', NULL, '')			THEN TMP_PRODUCT.B1_DESC		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION DESC')									THEN TMP_PRODUCT.B1_DESC		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE', 'PRICE ASC')								THEN TMP_PRODUCT.PRECO_APAGAR	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE DESC')										THEN TMP_PRODUCT.PRECO_APAGAR	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE', 'MIN_PRICE ASC')						THEN TMP_PRODUCT.DA1_ZPRCMI	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE DESC')									THEN TMP_PRODUCT.DA1_ZPRCMI	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE', 'SUG_PRICE ASC')						THEN TMP_PRODUCT.DA1_PRCVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE DESC')									THEN TMP_PRODUCT.DA1_PRCVEN	ELSE NULL END) DESC,

			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK', 'STOCK ASC')							THEN TMP_PRODUCT.B1_QATU		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK DESC')										THEN TMP_PRODUCT.B1_QATU		ELSE NULL END) DESC,
			
            (CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES', 'LAUNCHES ASC')							THEN TMP_PRODUCT.B1_ZPRDNOV		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES DESC')										THEN TMP_PRODUCT.B1_ZPRDNOV		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES', 'PURCHASES ASC')						THEN TMP_PRODUCT.D2_DTULTCP		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES DESC')									THEN TMP_PRODUCT.D2_DTULTCP		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS', 'BESTSELLERS ASC')					THEN TMP_PRODUCT.B1_ZQTDVEN		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS DESC','PURCHASES DESC')					THEN TMP_PRODUCT.B1_ZQTDVEN		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER', 'PRODUCT_CODE_ORDER ASC')		THEN TMP_PRODUCT.ORDEM_CODIGO	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER DESC')							THEN TMP_PRODUCT.ORDEM_CODIGO	ELSE NULL END) DESC
			
		OFFSET @PageNumber ROWS 
		FETCH NEXT @NumberRowsPerPage ROWS ONLY;

		RETURN;

	END;

	-- +-----------------------------------------------------+
	-- | QUANDO O PARÂMETRO @QueryResult IGUAL A 'PROMOTION' |
	-- +-----------------------------------------------------+
	IF @PromotionQueryExecute = 1 
	BEGIN;

		SELECT 
			TMP_PROMOTION.*,
			@ProductRowResult							AS PRODUCT_COUNT,
			@PromotionRowResult							AS PROMOTION_COUNT,
			(@ProductRowResult + @PromotionRowResult)	AS PRODUCT_PROMOTION_COUNT, 
			@BrandListObject							AS BRAND_LIST_OBJ,
			@CategoryListObject							AS CATEGORY_LIST_OBJ,
			@PromotionListObject						AS PROMOTION_LIST_OBJ
		FROM #TEMP_PROMOTION TMP_PROMOTION

		ORDER BY 
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE', 'CODE ASC')									THEN TMP_PROMOTION.B1_COD		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('CODE DESC')											THEN TMP_PROMOTION.B1_COD		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION', 'DESCRIPTION ASC', NULL, '')			THEN TMP_PROMOTION.B1_DESC		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('DESCRIPTION DESC')									THEN TMP_PROMOTION.B1_DESC		ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE', 'PRICE ASC')								THEN TMP_PROMOTION.PRECO_APAGAR	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRICE DESC')										THEN TMP_PROMOTION.PRECO_APAGAR	ELSE NULL END) DESC,			
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE', 'MIN_PRICE ASC')						THEN TMP_PROMOTION.DA1_ZPRCMI	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('MIN_PRICE DESC')									THEN TMP_PROMOTION.DA1_ZPRCMI	ELSE NULL END) DESC,
			
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE', 'SUG_PRICE ASC')						THEN TMP_PROMOTION.DA1_PRCVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('SUG_PRICE DESC')									THEN TMP_PROMOTION.DA1_PRCVEN	ELSE NULL END) DESC,

			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK', 'STOCK ASC')							THEN TMP_PROMOTION.B1_QATU		ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('STOCK DESC')										THEN TMP_PROMOTION.B1_QATU		ELSE NULL END) DESC,
			
            (CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES', 'LAUNCHES ASC')							THEN TMP_PROMOTION.B1_ZPRDNOV	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('LAUNCHES DESC')										THEN TMP_PROMOTION.B1_ZPRDNOV	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES', 'PURCHASES ASC')						THEN TMP_PROMOTION.D2_DTULTCP	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PURCHASES DESC')									THEN TMP_PROMOTION.D2_DTULTCP	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS', 'BESTSELLERS ASC')					THEN TMP_PROMOTION.B1_ZQTDVEN	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('BESTSELLERS DESC','PURCHASES DESC')					THEN TMP_PROMOTION.B1_ZQTDVEN	ELSE NULL END) DESC,
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER', 'PRODUCT_CODE_ORDER ASC')		THEN TMP_PROMOTION.ORDEM_CODIGO	ELSE NULL END),
			(CASE WHEN rTrim(Upper(@OrderByQuery)) IN ('PRODUCT_CODE_ORDER DESC')							THEN TMP_PROMOTION.ORDEM_CODIGO	ELSE NULL END) DESC

		OFFSET @PageNumber ROWS 
		FETCH NEXT @NumberRowsPerPage ROWS ONLY;

		RETURN;

	END;

END;
