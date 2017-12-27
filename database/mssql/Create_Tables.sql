USE master
GO

DECLARE @DB_NAME nvarchar(100) = N'TimeTopBookList';
DECLARE @SqlCommand nvarchar(MAX);

IF DB_ID(@DB_NAME) IS NULL
BEGIN
	SET @SqlCommand = 'CREATE DATABASE ' + @DB_NAME;
	EXEC sp_sqlexec @SqlCommand
END

:setvar database "TimeTopBookList"
USE $(database)

IF OBJECT_ID(N'dbo.Book') IS NOT NULL
	DROP TABLE dbo.Book
GO

IF OBJECT_ID(N'dbo.Author') IS NOT NULL
	DROP TABLE dbo.Author
GO

IF OBJECT_ID(N'dbo.CoverImage') IS NOT NULL
	DROP TABLE dbo.CoverImage
GO

CREATE TABLE Author
(
	AuthorID int IDENTITY(1,1) NOT NULL,
	AuthorName varchar(150) NOT NULL,
	CreatedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	ModifiedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT PK_AuthorID PRIMARY KEY CLUSTERED (AuthorID),
	CONSTRAINT AK_AuthorName UNIQUE(AuthorName)
);



CREATE TABLE CoverImage
(
	CoverImageID int IDENTITY(1,1) NOT NULL,
	ImageURL varchar(500) NOT NULL,
	ImageData nvarchar(MAX) NULL,
	CreatedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	ModifiedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT PK_CoverImage_ID PRIMARY KEY CLUSTERED(CoverImageID),
	CONSTRAINT AK_ImageURL UNIQUE(ImageURL)
)

CREATE TABLE Book
(
	BookID int IDENTITY(1,1) NOT NULL,
	Title varchar(250) NOT NULL,
	ListNumber tinyint NOT NULL,
	PreviousListNumber tinyint NULL,
	AuthorID int NOT NULL,
	CoverImageID int NULL,
	StartedReading datetime NULL,
	FinishedReading datetime NULL,
	CreatedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	ModifiedOn datetime NULL DEFAULT CURRENT_TIMESTAMP,
	StartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
	EndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (StartTime, EndTime),
	CONSTRAINT PK_Book_ID PRIMARY KEY CLUSTERED (BookID),
	CONSTRAINT FK_Author_AuthorID FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID),
	CONSTRAINT FK_CoverImage_CoverImageID FOREIGN KEY (CoverImageID) REFERENCES CoverImage(CoverImageID)
)
WITH
(
	SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.BookHistory)
);