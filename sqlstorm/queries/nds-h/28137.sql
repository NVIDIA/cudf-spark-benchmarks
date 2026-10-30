SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    MAX(SUBSTRING(s.s_name, 1, 15)) AS longest_supplier_name,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND p.p_type IN ('TypeA', 'TypeB', 'TypeC')
    AND c.c_acctbal > 1000
GROUP BY 
    short_name, nation_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_cost DESC
LIMIT 10;
