-- Create database ----
IF
(
	NOT EXISTS 
	(
		SELECT	1 
		FROM	[master].[dbo].[sysdatabases] 
		WHERE	'[' + name + ']' = '[Scrabble]'
	)
)
BEGIN
	CREATE DATABASE [Scrabble];
END;
GO

-- Use database ----
USE [Scrabble];
GO

-- Create tables ----
IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Person'
	)
)
BEGIN
    CREATE TABLE [dbo].[Person]
	(
		[Id] int IDENTITY(1,1),		
		[FirstName] nvarchar(50) NOT NULL,
		[LastName] nvarchar(50) NOT NULL,
		[DateOfBirth] nvarchar(50) NOT NULL,
		CONSTRAINT [PK_Person] PRIMARY KEY ([Id])
	);
END;
GO

IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Member'
	)
)
BEGIN
    CREATE TABLE [dbo].[Member]
	(
		[Id] int,
		[DateJoined] date NOT NULL,		
		CONSTRAINT [PK_Member] PRIMARY KEY ([Id]),
		CONSTRAINT [FK_Person_Member] FOREIGN KEY ([Id]) REFERENCES [dbo].[Person]([Id])
	);
END;
GO

IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Telephone'
	)
)
BEGIN
    CREATE TABLE [dbo].[Telephone]
	(
		[Id] int IDENTITY(1,1),		
		[MemberId] int NOT NULL,		
		[Number] nvarchar(13) NOT NULL,
		CONSTRAINT [PK_Telephone] PRIMARY KEY ([Id]),
		CONSTRAINT [FK_Member_Telephone] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Member]([Id])
	);
END;
GO

IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Email'
	)
)
BEGIN
    CREATE TABLE [dbo].[Email]
	(
		[Id] int IDENTITY(1,1),		
		[MemberId] int NOT NULL,		
		[Address] nvarchar(150) NOT NULL,
		CONSTRAINT [PK_Email] PRIMARY KEY ([Id]),
		CONSTRAINT [FK_Member_Email] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Member]([Id])
	);
END;
GO

IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Location'
	)
)
BEGIN
    CREATE TABLE [dbo].[Location]
	(
		[Id] int IDENTITY(1,1),		
		[Name] nvarchar(50) NOT NULL,
		[Longitude] decimal(9,6),
		[Latitude] decimal(9,6),
		CONSTRAINT [PK_Location] PRIMARY KEY ([Id])
	);
END;
GO

IF 
(
	NOT EXISTS 
	(
		SELECT	1 
        FROM	[INFORMATION_SCHEMA].[TABLES]
        WHERE	[TABLE_SCHEMA] = 'dbo'
				AND	[TABLE_NAME] = 'Match'
	)
)
BEGIN
    CREATE TABLE [dbo].[Match]
	(
		[Id] int IDENTITY(1,1),		
		[PlayerOneId] int NOT NULL,	
		[PlayerTwoId] int NOT NULL,
		[LocationId] int NOT NULL,		
		[PlayerOneScore] int NOT NULL,
		[PlayerTwoScore] int NOT NULL,
		[DatePlayed] date NOT NULL,
		CONSTRAINT [PK_Match] PRIMARY KEY ([Id]),
		CONSTRAINT [FK_Match_PlayerOne] FOREIGN KEY ([PlayerOneId]) REFERENCES [dbo].[Member]([Id]),
		CONSTRAINT [FK_Match_PlayerTwo] FOREIGN KEY ([PlayerTwoId]) REFERENCES [dbo].[Member]([Id]),
		CONSTRAINT [FK_Match_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location]([Id])
	);
END;
GO

-- Create stored procedures ----
IF 
(	
	EXISTS 
	( 
		SELECT  1
        FROM    [sys].[objects]
        WHERE   [name] = 'Member_Select'
                AND [type] IN ( N'P', N'PC' ) 
	)
)
BEGIN
	DROP PROCEDURE [dbo].[Member_Select];
END;
GO

CREATE PROCEDURE [dbo].[Member_Select]
	@id int
AS
BEGIN
	-- Narrow dataset to given player's games.
	CREATE TABLE #PlayerGames
	(
		[PlayerId] int,
		[OppositionId] int,
		[PlayerScore] int,
		[OppositionScore] int,
		[LocationId] int,
		[DatePlayed] date
	);

	INSERT INTO #PlayerGames ([PlayerId], [OppositionId], [PlayerScore], [OppositionScore], [LocationId], [DatePlayed])
	SELECT		ma.[PlayerId],
				ma.[OppositionId],
				ma.[PlayerScore],
				ma.[OppositionScore],
				ma.[LocationId],
				ma.[DatePlayed]
	FROM		(
					SELECT	[Id],
							CASE
								WHEN [PlayerOneId] = @id
								THEN [PlayerOneId]
								ELSE [PlayerTwoId]
							END AS 'PlayerId',
							CASE
								WHEN [PlayerOneId] <> @id
								THEN [PlayerOneId]
								ELSE [PlayerTwoId]
							END AS 'OppositionId',
							CASE
								WHEN [PlayerOneId] = @id
								THEN [PlayerOneScore]
								ELSE [PlayerTwoScore]
							END AS 'PlayerScore',
							CASE
								WHEN [PlayerOneId] <> @id
								THEN [PlayerOneScore]
								ELSE [PlayerTwoScore]
							END AS 'OppositionScore',
							[LocationId],
							[DatePlayed]
					FROM	[dbo].[Match]
					WHERE	[PlayerOneId] = @id
							OR	[PlayerTwoId] = @id
				) AS ma
	WHERE		ma.[PlayerId] = @id;

	-- Get their win count.
	DECLARE @WinCount AS int;

	SET @WinCount =
	(
		SELECT TOP(1)	COUNT([PlayerId])
		FROM			#PlayerGames
		WHERE			[PlayerScore] > [OppositionScore]
	);

	-- Get their loss count.
	DECLARE @LossCount AS int;

	SET @LossCount = 
	(
		SELECT TOP(1)	COUNT([PlayerId])
		FROM			#PlayerGames
		WHERE			[PlayerScore] < [OppositionScore]
	);

	-- Get their average score.
	DECLARE @AverageScore AS int;

	SET @AverageScore =
	(
		SELECT TOP(1)	AVG([PlayerScore])
		FROM			#PlayerGames
	);

	-- Return final dataset.
	SELECT TOP(1)	a.[PlayerId],
					p.[FirstName] + ' ' + p.[LastName] AS 'PlayerName',
					p.[DateOfBirth],
					t.[Number] AS 'TelephoneNumber',
					e.[Address] AS 'EmailAddress',					
					@WinCount AS 'WinCount',
					@LossCount AS 'LossCount',
					@AverageScore AS 'AverageScore',
					a.[PlayerScore] AS 'HighestScore',
					a.[DatePlayed] AS 'HighestDatePlayed',
					opp.[Id] AS 'HighestOpponentId',
					opp.[FirstName] + ' ' + opp.[LastName] AS 'HighestOpponentName',
					l.[Name] AS 'HighestLocation',
					l.[Longitude] AS 'HighestLongitude',
					l.[Latitude] AS 'HighestLatitude'
	FROM			#PlayerGames AS a
					LEFT OUTER JOIN	#PlayerGames AS b
									ON	a.[PlayerId] = b.[PlayerId] 
										AND a.[PlayerScore] < b.[PlayerScore]
					INNER JOIN		[dbo].[Person] AS opp
									ON	a.[OppositionId] = opp.[Id]
					INNER JOIN		[dbo].[Location] AS l
									ON	a.[LocationId] = l.[Id]
					INNER JOIN		[dbo].[Person] AS p
									ON	a.[PlayerId] = p.[Id]
									INNER JOIN	[dbo].[Telephone] AS t
												ON	p.[Id] = t.[MemberId]
									INNER JOIN	[dbo].[Email] AS e
												ON	p.[Id] = e.[MemberId]
	WHERE			b.[PlayerId] IS NULL;
END;
GO

IF 
(	
	EXISTS 
	( 
		SELECT  1
        FROM    [sys].[objects]
        WHERE   [name] = 'Leaderboard_Select'
                AND [type] IN ( N'P', N'PC' ) 
	)
)
BEGIN
	DROP PROCEDURE [dbo].[Leaderboard_Select];
END;
GO

CREATE PROCEDURE [dbo].[Leaderboard_Select]
AS
BEGIN
	SELECT TOP(10)	p.[Id] AS 'PlayerId',
					p.[FirstName] + ' ' + p.[LastName] AS 'PlayerName',
					AVG
					(
						CASE
							WHEN p.[Id] = ma.[PlayerOneId]
							THEN ma.[PlayerOneScore]
							ELSE ma.[PlayerTwoScore]
						END
					) AS 'AverageScore'
	FROM			[dbo].[Person] AS p
					INNER JOIN	[dbo].[Match] AS ma
								ON	p.[Id] = ma.[PlayerOneId]
									OR	p.[Id] = ma.[PlayerTwoId]
	GROUP BY		p.[Id],
					p.[FirstName] + ' ' + p.[LastName]
	HAVING			COUNT(ma.[Id]) > 10	
	ORDER BY		AVG
					(
						CASE
							WHEN p.[Id] = ma.[PlayerOneId]
							THEN ma.[PlayerOneScore]
							ELSE ma.[PlayerTwoScore]
						END
					) DESC;
END;
GO

-- Seed ----
-- Delete any existing data and reseed tables.
IF ((SELECT COUNT(*) FROM [dbo].[Match]) > 0)
BEGIN
	DELETE FROM [dbo].[Match];
	DBCC CHECKIDENT ('[Match]', RESEED, 0);
END;

IF ((SELECT COUNT(*) FROM [dbo].[Location]) > 0)
BEGIN
	DELETE FROM [dbo].[Location];	
	DBCC CHECKIDENT ('[Location]', RESEED, 0);
END;

IF ((SELECT COUNT(*) FROM [dbo].[Telephone]) > 0)
BEGIN
	DELETE FROM [dbo].[Telephone];
	DBCC CHECKIDENT ('[Telephone]', RESEED, 0);
END;

IF ((SELECT COUNT(*) FROM [dbo].[Email]) > 0)
BEGIN
	DELETE FROM [dbo].[Email];
	DBCC CHECKIDENT ('[Email]', RESEED, 0);
END;

IF ((SELECT COUNT(*) FROM [dbo].[Member]) > 0)
BEGIN
	DELETE FROM [dbo].[Member];
END;

IF ((SELECT COUNT(*) FROM [dbo].[Person]) > 0)
BEGIN
	DELETE FROM [dbo].[Person];
	DBCC CHECKIDENT ('[Person]', RESEED, 0);
END;

-- Add test data.
INSERT INTO [dbo].[Person] ([FirstName], [LastName], [DateOfBirth])
VALUES		('David', 'Gettins', '1991-10-16'),
			('Joe', 'Bloggs', '1982-05-01'),
			('Daniel', 'Parker', '1972-12-06'),
			('Marcus', 'Trent', '1986-05-09'),
			('Michelle', 'Daniels', '1988-07-15'),
			('Shannon', 'Zobel', '1995-02-18'),
			('Eilene', 'Alvarado', '1986-10-07'),
			('Lessie', 'Bennett', '1994-01-29'),
			('Lila', 'Collinsworth', '1990-04-12'),
			('Chantelle', 'Batton', '1965-04-08'),
			('Merle', 'Odum', '1978-11-10'),
			('Todd', 'Kitamura', '1968-05-05');

INSERT INTO [dbo].[Member] ([Id], [DateJoined])
VALUES		(1, '2005-09-09'),
			(2, '2007-11-15'),
			(3, '2008-08-13'),
			(4, '2008-09-10'),
			(5, '2009-09-07'),
			(6, '2009-09-09'),
			(7, '2009-04-23'),
			(8, '2009-05-21'),
			(9, '2009-09-02'),
			(10, '2009-12-07'),
			(11, '2009-03-25'),
			(12, '2009-12-27');
	
INSERT INTO [dbo].[Telephone] ([MemberId], [Number])
VALUES		(1, '+447111111111'),
			(2, '+447222222222'),
			(3, '+447333333333'),
			(4, '+447444444444'),
			(5, '+447555555555'),
			(6, '+447666666666'),
			(7, '+447777777777'),
			(8, '+447888888888'),
			(9, '+447999999999'),
			(10, '+447121212121'),
			(11, '+447131313131'),
			(12, '+447141414141');

INSERT INTO [dbo].[Email] ([MemberId], [Address])
SELECT		[Id], 
			LOWER([FirstName]) + '.' + LOWER([LastName]) + '@email.co.uk'
FROM		[dbo].[Person];

INSERT INTO [dbo].[Location] ([Name], [Longitude], [Latitude])
VALUES		('Manchester Central Convention Complex', -2.246441, 53.476567),
			('Manchester Metropolitan University', -2.238532, 53.471084);

INSERT INTO [dbo].[Match] ([PlayerOneId], [PlayerTwoId], [LocationId], [PlayerOneScore], [PlayerTwoScore], [DatePlayed])
VALUES		(1, 12, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(2, 11, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(3, 10, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(4, 9, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(5, 8, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(6, 7, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(7, 6, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(8, 5, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(9, 4, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(10, 3, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(11, 2, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),
			(12, 1, 2, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-04'),

			(1, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),

			(1, 11, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(2, 12, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(3, 1, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(4, 2, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(5, 3, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(6, 4, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(7, 5, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(8, 6, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(9, 7, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(10, 8, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(11, 9, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05'),
			(12, 10, 1, 100 + (700-100)*RAND(), 100 + (700-100)*RAND(), '2010-05-05');