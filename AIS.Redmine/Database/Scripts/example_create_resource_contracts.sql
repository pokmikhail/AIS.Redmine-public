SET NOCOUNT ON
DECLARE
	@commit BIT = 1,
	@maxId INT,
	@secondSideAH INT, -- Собственник или пользователь помещений МКД
	@secondSideIH INT, -- Собственник или пользователь помещений ЖД
	@rcByHouseAQTypeId INT,
	@queuedAQStatusId INT,
	@now date = SYSDATETIMEOFFSET()

	EXEC no.util@compact 'rate', 'ResourceContract'
	EXEC no.util@compact 'rate', 'ResourceContractResource'
	EXEC no.util@compact 'rate', 'ResourceContractObject'
	EXEC no.util@compact 'rate', 'ResourceContractObjectSupply'

-- prepare temp table
BEGIN
	DECLARE @i INT

	IF OBJECT_ID('tempdb..#metadata', 'U') IS NOT NULL DROP TABLE #metadata
	IF OBJECT_ID('tempdb..#msg', 'U') IS NOT NULL DROP TABLE #msg
	IF OBJECT_ID('tempdb..#insertedContract', 'U') IS NOT NULL DROP TABLE #insertedContract
	IF OBJECT_ID('tempdb..#oId', 'U') IS NOT NULL DROP TABLE #oId
	IF OBJECT_ID('tempdb..#qualityes', 'U') IS NOT NULL DROP TABLE #qualityes

	CREATE TABLE #metadata
	(
		SelectNum INT PRIMARY KEY,
		WorkSheetName NVARCHAR(50) COLLATE DATABASE_DEFAULT,
		HeaderFromColumnName BIT
	)

	INSERT #metadata ( SelectNum, WorkSheetName, HeaderFromColumnName )
	VALUES
		( 1, N'Сообщения обработки', 1 ),
		( 2, N'Созданные ДРСО', 1 )

	CREATE TABLE #msg(msg NVARCHAR(MAX) COLLATE DATABASE_DEFAULT)

	CREATE TABLE #insertedContract(id INT, number NVARCHAR(MAX) COLLATE DATABASE_DEFAULT)

	CREATE TABLE #oId(id INT)

	INSERT #oId(id)
	SELECT DISTINCT o.Id
	FROM no.[sr$PersonalAccountProvider] pap
		JOIN no.[cmn$Object] o ON pap.Accommodation_ObjectId = o.Id
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
	WHERE pap.ClosedReasonId IS NULL
		AND o.ComposedFullName LIKE 'Ленинградская%'
		AND pab.Id IS NULL

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' дома область'

	INSERT #oId(id)
	SELECT DISTINCT o.Id
	FROM no.[sr$PersonalAccountProvider] pap
		JOIN no.[cmn$Object] o ON pap.Accommodation_ObjectId = o.Id
		JOIN no.[cmn$Structure] s ON s.Id = o.StructureId
		JOIN no.[cmn$Address] a ON a.Id = s.AdrId
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
	WHERE pap.ClosedReasonId IS NULL
		AND o.ComposedFullName LIKE 'Санкт-Петербург%'
		AND a.Literal IS NOT NULL
		AND pab.AccountId IS NULL
		AND NOT EXISTS(SELECT 1 FROM #oid WHERE id = o.Id)

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' дома город. Есть литера'

	INSERT #oId(id)
	SELECT DISTINCT o.Id
	FROM no.[sr$PersonalAccountProvider] pap
		JOIN no.[cmn$Object] o ON pap.Accommodation_ObjectId = o.Id
		JOIN no.[cmn$Structure] s ON s.Id = o.StructureId
		JOIN no.[cmn$Address] a ON a.Id = s.AdrId
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
	WHERE pap.ClosedReasonId IS NULL
		AND o.ComposedFullName LIKE 'Санкт-Петербург%'
		AND a.Literal IS NULL
		AND a.Structure IS NOT NULL
		AND pab.AccountId IS NULL
		AND NOT EXISTS(SELECT 1 FROM #oid WHERE id = o.Id)

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' дома город. Строение без литеры'

	IF (OBJECT_ID('sandbox.green', 'U') IS NOT NULL)
	BEGIN
		INSERT #oId(id)
		SELECT DISTINCT o.Id
		FROM no.[sr$PersonalAccountProvider] pap
			JOIN no.[cmn$Object] o ON pap.Accommodation_ObjectId = o.Id
			JOIN sandbox.green g ON o.Id = g.objectId
			LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
		WHERE pap.ClosedReasonId IS NULL
			AND o.ComposedFullName LIKE 'Санкт-Петербург%'
			AND pab.AccountId IS NULL
			AND NOT EXISTS(SELECT 1 FROM #oid WHERE id = o.Id)

		INSERT #msg(msg)
		SELECT  STR(@@ROWCOUNT) + ' дома зеленые. Список из эксельки.'
	END

	-- check if contract already exists
	BEGIN
		BEGIN TRANSACTION

		INSERT no.[sr$PersonalAccountBase]
		(
			AccountId,
			ResourceContractId,
			IsGisSync,
			Created,
			Updated
		)
		SELECT
			DISTINCT
			pap.id,
			rc.Id,
			0,
			@now,
			SYSDATETIMEOFFSET()
		FROM #oId id
			JOIN rate.ResourceContractObject rco ON id.id = rco.ObjectId
			JOIN rate.ResourceContract rc ON rco.ResourceContractId = rc.Id
			JOIN no.[sr$PersonalAccountProvider] pap ON rc.Number = pap.AccountNumber
				AND rco.ObjectId = pap.Accommodation_ObjectId
				AND rc.OrganizationId = pap.OrganizationId
			LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
				AND pab.ResourceContractId = rc.Id
		WHERE pab.AccountId IS NULL
			AND rc.AnnulmentCause IS NULL
		SET @i = @@ROWCOUNT

		IF @commit = 1 COMMIT
		IF @commit = 0 AND @@TRANCOUNT > 0 ROLLBACK

		INSERT #msg(msg)
		SELECT STR(@i) + ' оснований найдено для ЛС'

		IF @i > 0 BEGIN
			DELETE id
			FROM #oId id
			WHERE NOT EXISTS (
					SELECT 1
					FROM no.[sr$PersonalAccountProvider] pap
						LEFT JOIN no.[sr$PersonalAccountBase] pab ON pap.Id = pab.AccountId
					WHERE pap.Accommodation_ObjectId = id.id
						AND pab.AccountId IS NULL
				)

			INSERT #msg(msg)
			SELECT '  ' + STR(@@ROWCOUNT) + ' домов исключено из дальнейшей обработки'
		END
	END

	CREATE TABLE #qualityes ([ResourceQualityTypeName] NVARCHAR(1000), [ResourceQualityTypeCode] NVARCHAR(1), [UnitId] INT, [Value] DECIMAL(20,6), [AdditionalInfo] NVARCHAR(500))

	INSERT INTO #qualityes
	VALUES
	(N'Частота', N'N', 144, 50.000000, N'Параметры качества электрической энергии для бытового потребления установлены ГОСТ 32144-2014. Допустимая продолжительность перерыва электроснабжения составляет 2 часа – при наличии двух независимых взаимно резервирующих источников питания и 24 часа – при наличии 1 источника. Информацию количестве источников питания, а также о сроках устранения аварий и иных нарушений качества электроснабжения, возникших во внутридомовых сетях, потребитель может получить в обслуживающей организации.' ), 
	(N'Напряжение (однофазная сеть)', N'N', 96, 220.000000, N'Параметры качества электрической энергии для бытового потребления установлены ГОСТ 32144-2014. Допустимая продолжительность перерыва электроснабжения составляет 2 часа – при наличии двух независимых взаимно резервирующих источников питания и 24 часа – при наличии 1 источника. Информацию количестве источников питания, а также о сроках устранения аварий и иных нарушений качества электроснабжения, возникших во внутридомовых сетях, потребитель может получить в обслуживающей организации.' ), 
	(N'Напряжение (трехфазная сеть)', N'N', 96, 380.000000, N'Параметры качества электрической энергии для бытового потребления установлены ГОСТ 32144-2014. Допустимая продолжительность перерыва электроснабжения составляет 2 часа – при наличии двух независимых взаимно резервирующих источников питания и 24 часа – при наличии 1 источника. Информацию количестве источников питания, а также о сроках устранения аварий и иных нарушений качества электроснабжения, возникших во внутридомовых сетях, потребитель может получить в обслуживающей организации.' )
END

BEGIN TRANSACTION
	SET XACT_ABORT ON
	-- rate.ResourceContract
	SELECT TOP 1 @maxId = MAX(id) FROM rate.ResourceContract rc
	IF @maxId IS NULL SET @maxId = 0

	SELECT TOP 1 @secondSideAH = Id
	FROM hm.FacetItems@get('rate.ResourceContract.SecondSideType')
	WHERE code = 'apartmentBuildingOwner'

	SELECT TOP 1 @secondSideIH = Id
	FROM hm.FacetItems@get('rate.ResourceContract.SecondSideType')
	WHERE code = 'livingHouseOwner'

	INSERT rate.ResourceContract
	(
		OrganizationId,
		SecondSideTypeId,
		IsIndividual,

		IsPublic,
		HasPlannedVolume,
		IsUOCounting,
		HasMeteringDeviceInformation,
		HasOneTimePayment,
		HasMeteringDepends,

		Number,
		DateSigned,
		DateStart,

		BillingDay,
		BillingDayNextMonth,
		ReadingsDayStart,
		ReadingsDayStartNextMonth,
		ReadingsDayEnd,
		ReadingsDayEndNextMonth,

		IsQualityIndicatorsByObjects,
		IsVolumeByObjects,

		Created,
		Updated
	)
	OUTPUT Inserted.Id, Inserted.Number INTO #insertedContract
	SELECT
		org.Id,
		CASE
			WHEN ot.Code in ('individualHouse')
			THEN @secondSideIH
			ELSE @secondSideAH
		END,
		1,

		1,
		0,
		NULL,
		1,
		0,
		1,

		pap.AccountNumber,
		pap.DateStart,
		pap.DateStart,

		20,
		1,
		1,
		0,
		-1,
		0,

		0,
		0,

		@now,
		SYSDATETIMEOFFSET()
	FROM #oId oId
		JOIN no.[sr$PersonalAccountProvider] pap ON pap.Accommodation_ObjectId = oId.id
		JOIN no.[cmn$Object] o ON o.Id = oId.id
		JOIN no.[cmn$Structure] s ON s.Id = o.StructureId
		JOIN no.[cmn$Address] a ON a.Id = s.AdrId
		JOIN no.[cmn$ObjectType] ot ON COALESCE(o.GisTypeId, o.TypeId) = ot.Id
		JOIN no.[cmn$Organization] org ON pap.OrganizationId = org.Id
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
	WHERE pab.AccountId IS NULL
		AND pap.ClosedReasonId IS NULL

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' создано ДРСО'

	INSERT rate.ResourceContractResource
	(
		ResourceContractId,
		ServiceGroupId,
		ResourceTypeId,
		DateStart,
		DateEnd,
		Created,
		Updated
	)
	SELECT
		rc.Id,
		sg.Id,
		rt.id,
		rc.DateStart,
		'21000101',
		@now,
		SYSDATETIMEOFFSET()
	FROM rate.ResourceContract rc
		JOIN no.[sr$ServiceGroupsHC] sg ON sg.Code = 'utility.powerSupply'
		JOIN rate.ResourceType rt ON rt.Code = 'powerEnergy'
	WHERE rc.Id > @maxId

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' добавлено ресурсов в ДРСО'

	INSERT rate.ResourceContractResourceQuality
	(
		ResourceContractResourceId,
		ResourceQualityTypeName,
		ResourceQualityTypeCode,
		UnitId,
		[Value],
		AdditionalInfo,
		Created,
		Updated
	)
	SELECT
		rcr.Id,
		q.ResourceQualityTypeName,
		q.ResourceQualityTypeCode,
		q.UnitId,
		q.[Value],
		q.AdditionalInfo,
		@now,
		@now
	FROM rate.ResourceContractResource rcr
		JOIN #qualityes q ON 1 = 1
	WHERE rcr.ResourceContractId > @maxId

	INSERT rate.ResourceContractObject
	(
		ResourceContractId,
		ObjectId,
		RoomNumber,
		ApartmentRoomNumber,
		Created,
		Updated
	)
	SELECT DISTINCT
		rc.Id,
		pap.Accommodation_ObjectId,
		CASE WHEN rc.SecondSideTypeId = @secondSideAH THEN COALESCE(r.Number, rr.Number) ELSE NULL END,
		CASE WHEN rc.SecondSideTypeId = @secondSideAH THEN ar.Number ELSE r.Number END,
		@now,
		SYSDATETIMEOFFSET()
	FROM rate.ResourceContract rc
		JOIN no.[sr$PersonalAccountProvider] pap ON rc.Number = pap.AccountNumber AND rc.OrganizationId = pap.OrganizationId
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
		LEFT JOIN no.[od$Room] r ON pap.Accommodation_RoomId = r.Id
		LEFT JOIN no.[od$ApartmentRoom] ar ON pap.Accommodation_ApartmentRoomId = ar.Id
		LEFT JOIN no.[od$Room] rr ON rr.Id = ar.RoomId
	WHERE rc.Id > @maxId
		AND pab.AccountId IS NULL
		AND pap.ClosedReasonId IS NULL

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' добавлено объектов в ДРСО'

	INSERT rate.ResourceContractObjectSupply
	(
		RecourceContractObjectId,
		ResourceContractResourceId,
		DateStart,
		DateEnd,
		Created,
		Updated
	)
	SELECT
		rco.Id,
		rcr.Id,
		rc.DateStart,
		'21000101',
		@now,
		SYSDATETIMEOFFSET()
	FROM rate.ResourceContract rc
		JOIN rate.ResourceContractObject rco ON rc.Id = rco.ResourceContractId
		JOIN rate.ResourceContractResource rcr ON rc.Id = rcr.ResourceContractId
	WHERE rc.Id > @maxId

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' добавлено ресурсов на дома в ДРСО'

	INSERT no.[sr$PersonalAccountBase]
	(
		AccountId,
		ResourceContractId,
		IsGisSync,
		Created,
		Updated
	)
	SELECT
		DISTINCT
		pap.id,
		rc.Id,
		0,
		@now,
		SYSDATETIMEOFFSET()
	FROM rate.ResourceContract rc
		JOIN rate.ResourceContractObject rco ON rco.ResourceContractId = rc.Id
		JOIN no.[sr$PersonalAccountProvider] pap ON rc.Number = pap.AccountNumber
			AND rco.ObjectId = pap.Accommodation_ObjectId
			AND rc.OrganizationId = pap.OrganizationId
		LEFT JOIN no.[sr$PersonalAccountBase] AS pab ON pab.AccountId = pap.Id
			AND pab.ResourceContractId = rc.Id
	WHERE pab.AccountId IS NULL
		AND rc.AnnulmentCause IS NULL

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' оснований добавлено к ЛС'

	-- OTOL
	INSERT no.[cmn$ObjectToOrganizationLink]
	(
		ObjectId,
		OrganizationId,
		TypeId,
		DateStart,
		Created,
		Updated
	)
	SELECT
		rco.ObjectId,
		rc.OrganizationId,
		otolt.Id TypeId,
		MIN(rc.DateStart),
		@now,
		SYSDATETIMEOFFSET()
	FROM rate.ResourceContract rc
		JOIN rate.ResourceContractObject rco ON rco.ResourceContractId = rc.Id
		JOIN rate.ResourceContractObjectSupply rcos ON rcos.RecourceContractObjectId = rco.Id
		JOIN no.[cmn$ObjectToOrganizationLinkType] otolt ON otolt.Code = 'resourceSupply'
		LEFT JOIN no.[cmn$ObjectToOrganizationLink] x ON rco.ObjectId = x.ObjectId AND rc.OrganizationId = x.OrganizationId
	WHERE x.ObjectId IS NULL
		AND rc.AnnulmentDate IS NULL
		AND rc.TerminationDate IS NULL
		AND ISNULL(rc.GisIsIgnored, 0) = 0
		AND (rc.DateEnd IS NULL OR rc.DateEnd > @now)
		AND (rcos.DateEnd IS NULL OR rcos.DateEnd > @now)
	GROUP BY rco.ObjectId, rc.OrganizationId, otolt.Id

	INSERT #msg(msg)
	SELECT STR(@@ROWCOUNT) + ' создано привязок на дома создано'

	-- select this data here to show all messages when @commit = 0
	SELECT SelectNum, WorkSheetName, HeaderFromColumnName
	FROM #metadata

	SELECT msg [Сообщение]
	FROM #msg

	SELECT
		id [Идентификатор договора],
		number [Номер договора]
	FROM #insertedContract

	IF @@TRANCOUNT > 0 AND @commit = 1 BEGIN
		COMMIT

		INSERT #msg(msg)
		SELECT 'Сохраняем!'
	END

IF @@TRANCOUNT > 0 BEGIN
	ROLLBACK

	INSERT #msg(msg)
	SELECT 'Отменяем!'
END

DROP TABLE #metadata
DROP TABLE #msg
DROP TABLE #insertedContract
DROP TABLE #oId
DROP TABLE #qualityes
