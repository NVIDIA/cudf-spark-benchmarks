
SELECT 
    p.p_name, 
    s.s_name, 
    SUBSTRING(s.s_address, 1, 20) AS short_address,
    CONCAT(r.r_name, ' - ', n.n_name) AS location,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_quantity) AS max_line_quantity,
    MIN(o.o_totalprice) AS min_order_total
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
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name, short_address, r.r_name, n.n_name 
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1 
ORDER BY 
    average_supply_cost DESC, max_line_quantity ASC 
LIMIT 100;
