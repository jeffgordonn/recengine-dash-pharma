-- Allows us to store leading values as ints for IDs (presumption is IDs are fixed length across their distribution) or other ID concats
CREATE FUNCTION PATIENTSDW.dbo.ZFill(@ID INT, @n INT)
RETURNS INT
WITH EXECUTE AS CALLER
AS 
BEGIN
    -- create initial object
    DECLARE @zfill VARCHAR(@n) = @ID;
    -- find the amount of zeroes needed to fill the fixed length
    DECLARE @zeroes INT = @n - len(@zfill);
    -- concat it together
    DECLARE @VarcharZeroFilledID VARCHAR(@n) = CONCAT(@zfill,REPLICATE('0',@zeroes));

    RETURN (@VarcharZeroFilledID);
END;
go

-- Modify the column passed so that this
CREATE FUNCTION PATIENTSDW.dbo.HandleNulls(@table TABLE, @col VARCHAR(50), @NULLMethod VARCHAR(10))
WITH EXECUTE AS CALLER
BEGIN
    IF @NullMethod = 'Zero'
    BEGIN

    END
    ELSE IF @NullMethod = 'AVG'
    BEGIN

    END
    ELSE IF @NullMethod = 'MED'
    BEGIN

    END
    ELSE
    BEGIN
    -- the null method in this case will be assumed as the replacable value here, essentially this is the `custom_input` option a py dict would pass
    SET @SQL = '
    UPDATE tab
    '

    END
END


CREATE FUNCTION PATIENTSDW.dbo.Standardization(Column TABLE)
RETURNS TABLE
WITH EXECUTE AS CALLER
AS 
BEGIN
    -- Classical z score standardization


END;
go

CREATE FUNCTION PATIENTSDW.dbo.CosineSimilarity(A_s TABLE, B_s TABLE)
RETURNS FLOAT
WITH EXECUTE AS CALLER
AS 
BEGIN
    

END;
go

CREATE FUNCTION PATIENTSDW.dbo.L1Distance(X_s TABLE, Y_s TABLE)
RETURNS FLOAT
WITH EXECUTE AS CALLER
AS 
BEGIN
    -- So to be able to easily take the single row here, we can just cross join the info to the Y table
    -- lets use somemore dynamic sql so we dont need to write out everything lmao

END;
go

CREATE FUNCTION PATIENTSDW.dbo.L2Distance(X_s TABLE, Y_s TABLE)
RETURNS FLOAT
WITH EXECUTE AS CALLER
AS 
BEGIN
    

END;
go

-- This will not only check the vectors for = lengths and column values, but I am going to reoganize the columns for ensurance of proper alignment on dims, additionally
-- Table 1 should be 1 row, as it is the anchor
-- Table 2 should be a matrix of size m,n; where m = each distinct HCP, n = patient service features
CREATE PROCEDURE PATIENTSDW.dbo.RecommendHCPbyPatient(
    @table1 VARCHAR(MAX), @schema1 VARCHAR(50), @db1 VARCHAR(MAX),
    @table2 VARCHAR(MAX), @schema2 VARCHAR(50), @db2 VARCHAR(MAX),
    @W_cos FLOAT, @W_l1 FLOAT, @W_l2 FLOAT,
    @NULLMethod VARCHAR(10)
)
AS
BEGIN
    -- 0. ================= CALCULATE WEIGHTS FOR COMPOUND SIM SCORE ===================
    -- While yes, people should intentionally place probability weights that = 1, we will allow a more robust ingestion by normalizing by the total divided by the component. 
    DECLARE @weightTotal FLOAT = @W_cos + @W_l1 + @W_l2
    SET @W_cos /= @weightTotal
    SET @W_l1 /= @weightTotal
    SET @W_l2 /= @weightTotal

    -- 1. ================= CHECKING VECTOR DIMS ===================
    -- create the column name table recepticle
    DECLARE @table1cols TABLE(columnNames SYSNAME);
    -- using dynamic SQL, we will use the sys tables to grab the relevant info for the tables to get columns from the exact db.schema.table
    DECLARE @SQL VARCHAR(MAX)
    SET @SQL = '
    INSERT INTO @table1cols
    SELECT col.name
        FROM '+ QUOTENAME(@db1) +'.sys.tables tab
        INNER JOIN '+ QUOTENAME(@db1) +'.sys.schemas sc ON tab.schema_id = sc.schema_id
        INNER JOIN '+ QUOTENAME(@db1) +'.sys.columns col ON tab.object_id = tab.object_id
            WHERE sc.name = '+QUOTENAME(@schema1)+'
            AND tab.name = '+QUOTENAME(@table1)+'
    '
    EXECUTE @SQL

    -- same deal as above
    DECLARE @table2cols TABLE(columnNames SYSNAME);
    SET @SQL = '
    INSERT INTO @table1cols
    SELECT col.name
        FROM '+ QUOTENAME(@db2) +'.sys.tables tab
        INNER JOIN '+ QUOTENAME(@db2) +'.sys.schemas sc ON tab.schema_id = sc.schema_id
        INNER JOIN '+ QUOTENAME(@db2) +'.sys.columns col ON tab.object_id = tab.object_id
            WHERE sc.name = '+QUOTENAME(@schema2)+'
            AND tab.name = '+QUOTENAME(@table2)+'
    '
    EXECUTE @SQL

    -- check to see if these two are the same
    IF EXISTS ( -- TRUE: The column names have at least 1 differing value, FALSE: The columns are equivalents
        SELECT columnNames FROM @table1cols
        EXCEPT
        SELECT columnNames FROM @table2cols
    )
    BEGIN
        -- THis could be handled differently but for now let's enforce the passed values to have equivalent colnames as this will be the easiest way to ensure no difference between the column lengths
        PRINT 'Columns passed are not equivalent. Please ensure the same number of columns and same names are passed'
        BREAK
    END
    ELSE
    BEGIN
        -- Since they are the same, we will now pass the master column names to be used to set the rows in the calcs
        DECLARE @uniColumnOrder TABLE(columnName);
        SELECT columnNames FROM @table1cols
        INTO @uniformColumn
        INTERSECT
        SELECT columnNames FROM @table2cols
    END
    -- 2. ================= CALCULATING DIST/SIMS ===================
    -- 2a. ============== L1 ==============

    -- 2b. ============== L2 ==============

    -- 2c. ============== Cosine ==============
END;
go

