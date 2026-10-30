SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    p.p_brand,
    ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost,
    REPLACE(UPPER(p.p_comment), 'OUTDATED', 'UPDATED') AS updated_comment,
    SUBSTRING(p.p_type, 1, 10) AS short_type,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 500.00
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name, p.p_brand, p.p_comment, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_supply_cost DESC, last_order_date ASC;
