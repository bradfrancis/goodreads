DROP FUNCTION IF EXISTS Staging.LoadJSON;

CREATE FUNCTION Staging.LoadJSON(json_data text)
RETURNS TABLE(id int, err_msg text) 
AS $$
DECLARE
	insert_id int := NULL;
	err_context text;
BEGIN
  -- Insert JSON into the Staging table
	INSERT INTO Staging.JSONImport (raw_data)
	SELECT json_data::json AS raw_data
	RETURNING json_import_id INTO insert_id;
	
	-- Return the id of the newly inserted row
	RETURN QUERY SELECT insert_id, err_context;
	
	-- Handle any exceptions
	EXCEPTION WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
		RAISE INFO 'Error Name: %', SQLERRM;
		RAISE INFO 'Error State: %', SQLSTATE;
		RAISE INFO 'Error Context: %', err_context;
		RETURN QUERY SELECT -1, err_context; --SQLSTATE; --SQLERRM::text;
END;
$$ LANGUAGE plpgsql;