SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, ' | Part: ', p.p_name, ' | Orders Processed: ', COUNT(o.o_orderkey)) AS summary_info,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(l.l_quantity) AS total_quantity,
    MAX(l.l_extendedprice) AS max_extended_price
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE '%United%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, n.n_name, p.p_name
ORDER BY 
    total_quantity DESC;