WITH processed_data AS (
    SELECT 
        p.p_name,
        s.s_name,
        r.r_name,
        CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name, ', Product: ', p.p_name) AS combined_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name, ', Product: ', p.p_name)) AS info_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_retailprice > 50
)
SELECT 
    combined_info,
    info_length,
    SUBSTRING(combined_info, 1, 50) AS short_info,
    REPLACE(combined_info, 'Supplier: ', '[Supplier] ') AS modified_info
FROM 
    processed_data
ORDER BY 
    info_length DESC
LIMIT 10;
