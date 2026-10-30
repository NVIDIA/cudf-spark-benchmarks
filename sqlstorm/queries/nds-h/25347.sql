SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_part_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    MAX(l.l_tax) AS max_tax_rate
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey 
WHERE 
    p.p_size BETWEEN 10 AND 25 
    AND s.s_acctbal > 1000 
    AND l.l_shipdate >= '1996-01-01' 
GROUP BY 
    SUBSTRING(p.p_name, 1, 20)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 
ORDER BY 
    total_quantity DESC;