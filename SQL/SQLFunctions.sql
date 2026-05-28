-- Allows us to store leading values as ints for IDs (presumption is IDs are fixed length across their distribution) or other ID concats
CREATE FUNCTION ZFill(ID INT, n INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    zfill TEXT;
    ZeroFilledID TEXT;
BEGIN
    -- create initial object
    zfill := TRY_CAST(ID as TEXT);
    -- concat it together
    VarcharZeroFilledID := CONCAT(zfill,REPLICATE('0',n - len(zfill)));

    RETURN ZeroFilledID;
END;
$$;


-- Modify the column passed so that this
CREATE FUNCTION HandleNulls(table TABLE, col TEXT, NULLMethod TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN
    IF NullMethod = 'Zero'
    BEGIN

    END
    ELSE IF NullMethod = 'AVG'
    BEGIN

    END
    ELSE IF NullMethod = 'MED'
    BEGIN

    END
    ELSE
    BEGIN
    -- the null method in this case will be assumed as the replacable value here, essentially this is the `custom_input` option a py dict would pass
    SQL := '
    UPDATE tab
    '

    END;
END;
$$;

---- Standardization for normization
CREATE FUNCTION Standardization(table_name pgclass)
RETURNS pgclass
LANGUAGE plpgsql
AS $$
DECLARE 

BEGIN
    -- Classical z score standardization
    -- Will individually standardize all of the records in each column


END;


------- Cosine Sim Functions
CREATE OR REPLACE FUNCTION DotProduct(A_s TEXT, B_s TEXT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE 
    dotprodstatement TEXT;
    sql TEXT;
    dot_p DOUBLE PRECISION; 
BEGIN
    -- Create Inner Multiplication
    SELECT string_agg(
        format('COALESCE(t1.%I) * COALESCE(t2.%I)',column_name,column_name)
    ,' + ') -- Sum component
    INTO dotprodstatement
    -- since we have a function to check the dims, column names either would suffice
    FROM information_schema.columns
    WHERE table_schema = 'public'
        AND table_name = A_s

    -- dot product of the passed arrays
    SQL := format('
    SELECT %s as dot_p
    FROM public.%I t1 CROSS JOIN public.%I t2
    ',dotprodstatement, A_s, B_s)
    -- execute statement
    EXECUTE SQL INTO dot_p;
    RETURN dot_p
END;
$$;

CREATE OR REPLACE FUNCTION FrobeniusNorm(table_name TEXT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE
    squared_sum TEXT;
    sql TEXT;
    frob_num double precision;
BEGIN
    -- **2
    SELECT string_agg(
        format('COALESCE(%I)**2',column_name,column_name)
    ,' + ') -- sum comp
    INTO squared_sum
    FROM information_schema.columns
        WHERE table_schema = 'public'
            AND table_name = table_name
    -- sqrt the summed power
    SQL := format('
    SELECT SQRT(%s) as frob_norm
    FROM public.%I
    ',dotprodstatement, table_name)

    EXECUTE SQL INTO frob_norm;
    RETURN frob_norm;
END;
$$;

CREATE OR REPLACE FUNCTION CosineSimilarity_Row(A_s TEXT, B_s TEXT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE
    cossim double precision
BEGIN
    cossim := DotProduct(A_s,B_s)/(FrobeniusNorm(A_s)*FrobeniusNorm(B_s))
    RETURN cossim;
END;
$$;

------ Manhattan Distance
CREATE OR REPLACE FUNCTION L1Distance_Row(X_s TABLE, Y_s TABLE)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN
    -- So to be able to easily take the single row here, we can just cross join the info to the Y table
    -- lets use somemore dynamic sql so we dont need to write out everything lmao

END;
$$;

------ Euclidean Distance
CREATE OR REPLACE FUNCTION L2Distance_Row(X_s TABLE, Y_s TABLE)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE 

BEGIN



END;
SS;

-- This will not only check the vectors for = lengths and column values, but I am going to reoganize the columns for ensurance of proper alignment on dims, additionally
-- Table 1 should be 1 row, as it is the anchor
-- Table 2 should be a matrix of size m,n; where m = each distinct HCP, n = patient service features
CREATE OR REPLACE FUNCTION RecommendHCPbyPatient(
    table1 regclass, table2 regclass,
    W_cos FLOAT, W_l1 FLOAT, W_l2 FLOAT,
    NULLMethod TEXT
)
RETURNS TABLE (
    dot_product_result double precison
)
AS $$
DECLARE
    weightTotal double precision;
    W_cos_norm double precision;
    W_l1_norm  double precision;
    W_l2_norm  double precision;
BEGIN
    -- 0. ================= CALCULATE WEIGHTS FOR COMPOUND SIM SCORE ===================
    -- While yes, people should intentionally place probability weights that = 1, we will allow a more robust ingestion by normalizing by the total divided by the component. 
    weightTotal := W_cos + W_l1 + W_l2
    W_cos_norm := W_cos / weightTotal
    W_l1_norm := W_l1 / weightTotal
    W_l2_norm := W_l2 / weightTotal

    -- 1. ================= CHECKING VECTOR DIMS ===================
    -- create the column name table recepticle
    CREATE TEMP TABLE IF NOT EXISTS table1cols (
        column_name TEXT
    ) ON COMMIT DROP;

    INSERT INTO table1cols (column_name)
    SELECT c.column_name
        FROM information_schema.columns c
            WHERE c.table_schema = 'public' -- deciding whether this should be hard coded
            AND c.table_name = table1
                ORDER BY c.ordinal_position

    -- same deal as above
    CREATE TEMP TABLE IF NOT EXISTS table2cols (
        column_name TEXT
    ) ON COMMIT DROP;

    INSERT INTO table2cols (column_name)
    SELECT c.column_name
        FROM information_schema.columns c
            WHERE c.table_schema = 'public' -- deciding whether this should be hard coded
            AND c.table_name = table1
                ORDER BY c.ordinal_position

    -- check to see if these two are the same
    IF EXISTS ( -- TRUE: The column names have at least 1 differing value, FALSE: The columns are equivalents
        SELECT columnNames FROM table1cols
        EXCEPT
        SELECT columnNames FROM table2cols
    ) OR
    EXISTS (
        SELECT columnNames FROM table2cols
        EXCEPT
        SELECT columnNames FROM table1cols
    )
    THEN
        -- THis could be handled differently but for now let's enforce the passed values to have equivalent colnames as this will be the easiest way to ensure no difference between the column lengths
        RAISE EXCEPTION 'Columns passed are not equivalent. Please ensure the same number of columns and same names are passed'
    ELSE
        -- Since they are the same, we will now pass the master column names to be used to set the rows in the calcs
        CREATE TEMP TABLE uniform_columns AS
            SELECT column_name FROM table1cols
            INTERSECT
            SELECT column_name FROM table2cols
    END IF;
    -- 2. ================= CALCULATING DIST/SIMS ===================
    -- 2a. ============== L1 ==============

    -- 2b. ============== L2 ==============

    -- 2c. ============== Cosine ==============
END;


