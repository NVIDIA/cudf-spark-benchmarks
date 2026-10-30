
WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
FormattedDetails AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part Name: ', p.p_name, ', Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, 
               ', Type: ', p.p_type, ', Size: ', p.p_size, 
               ', Retail Price: ', p.p_retailprice, ', Returns: ', p.total_returned, 
               ', Unique Suppliers: ', p.unique_suppliers) AS formatted_string
    FROM 
        PartDetails p
)
SELECT 
    p.p_partkey AS partkey,
    p.formatted_string,
    LENGTH(p.formatted_string) AS formatted_length,
    CHAR_LENGTH(p.formatted_string) AS char_length,
    REPLACE(REPLACE(p.formatted_string, ' ', ''), ',', '') AS string_without_spaces
FROM 
    FormattedDetails p
WHERE 
    LENGTH(p.formatted_string) > 100
ORDER BY 
    LENGTH(p.formatted_string) DESC;
