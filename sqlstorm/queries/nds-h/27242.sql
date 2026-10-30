WITH string_aggregations AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(SUBSTRING(p.p_name FROM 1 FOR 10), '...', SUBSTRING(p.p_name FROM LENGTH(p.p_name) - 9 FOR 10)) AS truncated_name,
        UPPER(p.p_comment) AS upper_comment,
        REPLACE(p.p_comment, 'excellent', 'superb') AS modified_comment
    FROM 
        part p
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        r.r_name AS region_name,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Region: ', r.r_name) AS full_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sa.p_partkey,
    sa.truncated_name,
    sa.upper_comment,
    sd.full_details
FROM 
    string_aggregations sa
JOIN 
    supplier_details sd ON sa.p_partkey % 1000 = sd.s_suppkey % 1000  
WHERE 
    sa.p_partkey < 1000
ORDER BY 
    sa.p_partkey ASC
LIMIT 20;