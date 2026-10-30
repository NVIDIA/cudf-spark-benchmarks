WITH StringBenchmark AS (
    SELECT 
        P.p_name,
        CONCAT(S.s_name, ' - ', P.p_type) AS SupplierType,
        LENGTH(P.p_comment) AS CommentLength,
        REPLACE(P.p_comment, ' ', '') AS NoSpaceComment,
        SUBSTRING(P.p_name, 1, 10) AS ShortName,
        UPPER(P.p_mfgr) AS UpperManufacturer,
        LOWER(P.p_brand) AS LowerBrand,
        TRIM(P.p_comment) AS TrimmedComment,
        REGEXP_REPLACE(P.p_comment, '[^a-zA-Z0-9]', '') AS AlphanumericComment
    FROM 
        part P
    JOIN 
        partsupp PS ON P.p_partkey = PS.ps_partkey
    JOIN 
        supplier S ON PS.ps_suppkey = S.s_suppkey
    WHERE 
        LENGTH(P.p_name) > 5 AND 
        P.p_retailprice > 50.00
)
SELECT 
    COUNT(*) AS TotalRecords,
    AVG(CommentLength) AS AvgCommentLength,
    MAX(LENGTH(SupplierType)) AS MaxSupplierTypeLength,
    MIN(LENGTH(UpperManufacturer)) AS MinUpperManufacturerLength
FROM 
    StringBenchmark
WHERE 
    ShortName LIKE 'AB%';
