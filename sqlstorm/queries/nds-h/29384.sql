
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    SUM(CASE 
        WHEN CHAR_LENGTH(p.p_name) BETWEEN 10 AND 30 THEN 1 
        ELSE 0 
    END) AS medium_length_name_count,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', r.r_name), '; ') AS nation_region_details
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
    p.p_size IN (5, 10, 15)
GROUP BY 
    p.p_mfgr
ORDER BY 
    supplier_count DESC, total_avail_qty DESC
LIMIT 100;
