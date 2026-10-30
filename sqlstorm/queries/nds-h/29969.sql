SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_balance,
    r.r_name AS region_name,
    CASE 
        WHEN AVG(l.l_extendedprice) > 1000 THEN 'High Value'
        WHEN AVG(l.l_extendedprice) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
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
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    short_part_name, region_name
ORDER BY 
    total_available_quantity DESC, average_supplier_balance ASC
LIMIT 50;