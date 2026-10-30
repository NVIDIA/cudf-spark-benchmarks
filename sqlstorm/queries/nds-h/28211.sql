SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_info,
    REPLACE(p.p_comment, 'fragile', 'delicate') AS modified_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    r.r_name AS region_name
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
    p.p_size > 10
    AND p.p_retailprice BETWEEN 100.00 AND 500.00
GROUP BY 
    short_name, mfgr_info, modified_comment, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_available_quantity DESC
LIMIT 20;
