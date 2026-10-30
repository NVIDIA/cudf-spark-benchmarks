
WITH String_Benchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Price: ', p.p_retailprice) AS Combined_String,
        LENGTH(p.p_name) AS Name_Length,
        LENGTH(s.s_name) AS Supplier_Name_Length,
        LENGTH(CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Price: ', p.p_retailprice)) AS Combined_String_Length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
        AND s.s_acctbal > 500.00
)
SELECT 
    COUNT(*) AS Total_Records,
    AVG(Name_Length) AS Avg_Part_Name_Length,
    AVG(Supplier_Name_Length) AS Avg_Supplier_Name_Length,
    MAX(Combined_String_Length) AS Max_Combined_String_Length,
    MIN(Combined_String_Length) AS Min_Combined_String_Length
FROM 
    String_Benchmark;
