
WITH StringBenchmark AS (
    SELECT 
        p.p_name AS PartName,
        CONCAT(s.s_name, ' - ', s.s_address) AS SupplierDetails,
        CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS LocationDetails,
        SUBSTRING(p.p_comment, 1, 10) AS ShortComment,
        REPLACE(p.p_comment, ' ', '_') AS UnderscoreComment,
        LENGTH(p.p_name) AS NameLength,
        CHAR_LENGTH(s.s_name) AS SupplierNameLength
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size > 10
)
SELECT 
    PartName, 
    SupplierDetails, 
    LocationDetails, 
    ShortComment, 
    UnderscoreComment, 
    NameLength, 
    SupplierNameLength
FROM StringBenchmark
WHERE 
    SupplierNameLength BETWEEN 5 AND 15 
    AND NameLength >= 8
LIMIT 50;
