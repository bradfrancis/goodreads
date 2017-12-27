USE TimeTopBookList
GO

IF OBJECT_ID(N'dbo.usp_BookListUpdate', N'P') IS NOT NULL
	DROP PROCEDURE dbo.usp_BookListUpdate
GO

CREATE PROCEDURE dbo.usp_BookListUpdate
(
	@json NVARCHAR(MAX)
)
AS
BEGIN

	DECLARE @TempData TABLE
	(
		BookID int,
		ListNumber tinyint,
		Title varchar(250),
		AuthorName varchar(200),
		ImageURL varchar(500),
		ImageData nvarchar(MAX),
		UpdateStatus varchar(50)
	)
	
	INSERT INTO @TempData
	(
		ListNumber,
		Title,
		AuthorName,
		ImageURL,
		ImageData
	)
	SELECT ListNumber
		  ,Title
		  ,AuthorName
		  ,ImageURL
		  ,ImageData 
	FROM OPENJSON(@json)
	WITH (
		ListNumber tinyint '$.number',
		Title varchar(250) '$.title',
		AuthorName varchar(200) '$.author',
		ImageURL varchar(500) '$.img_url',
		ImageData nvarchar(MAX) '$.img_data'
	
	)

	BEGIN TRY
		BEGIN TRANSACTION

		-- Insert new Authors
		INSERT INTO dbo.Author (AuthorName)
		SELECT DISTINCT T.AuthorName
		FROM   @TempData AS T
		LEFT JOIN dbo.Author AS A ON A.AuthorName = T.AuthorName
		WHERE  A.AuthorID IS NULL;
		
		-- Insert new cover images
		INSERT INTO dbo.CoverImage (ImageURL, ImageData)
		SELECT DISTINCT T.ImageURL
		      ,T.ImageData
		FROM   @TempData AS T
		LEFT JOIN dbo.CoverImage AS CI ON CI.ImageURL = T.ImageURL
		WHERE  CI.CoverImageID IS NULL;
		
		-- Determine if update or insert
		UPDATE T
		SET    UpdateStatus = (CASE WHEN B.BookID IS NULL THEN 'NEW' ELSE 'UPDATE' END)
		FROM   @TempData AS T
		LEFT JOIN dbo.Book AS B ON B.Title = T.Title;
		
		-- Insert new books
		INSERT INTO dbo.Book
		(
			Title,
			ListNumber,
			AuthorID,
			CoverImageID
		)
		SELECT T.Title
		      ,T.ListNumber
			  ,A.AuthorID
			  ,CI.CoverImageID
		FROM   @TempData AS T
		JOIN   dbo.Author AS A ON A.AuthorName = T.AuthorName
		JOIN   dbo.CoverImage AS CI ON CI.ImageURL = T.ImageURL
		WHERE  T.UpdateStatus = 'NEW';
		
		-- Update books
		UPDATE B
		SET    ListNumber = T.ListNumber,
		       PreviousListNumber = B.ListNumber,
			   AuthorID = A.AuthorID,
			   CoverImageID = CI.CoverImageID,
			   ModifiedOn = CURRENT_TIMESTAMP
		FROM   @TempData AS T
		JOIN   dbo.Book AS B ON B.Title = T.Title
		JOIN   dbo.Author AS A ON A.AuthorName = T.AuthorName
		JOIN   dbo.CoverImage AS CI ON CI.ImageURL = T.ImageURL
		WHERE  T.UpdateStatus = 'UPDATE';

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION
		END

		SELECT ERROR_NUMBER() AS ErrorNumber,
			   ERROR_SEVERITY() AS ErrorSeverity,
			   ERROR_STATE() AS ErrorState,
			   ERROR_PROCEDURE() AS ErrorProcedure,
			   ERROR_LINE() AS ErrorLine,
			   ERROR_MESSAGE() AS ErrorMessage
	END CATCH
END