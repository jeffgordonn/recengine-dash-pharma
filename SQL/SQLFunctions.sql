-- Allows us to store leading values as ints for IDs (presumption is IDs are fixed length) or other ID concats

CREATE FUNCTION PATIENTSDW.dbo.ZFill(ID INT, n INT)
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
Go