SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name AS supplier_nation, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Part:', p.p_name, ' | Supplier:', s.s_name, ' | Nation:', n.n_name) AS detail_summary
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 
    AND l.l_returnflag = 'N' 
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, supplier_nation;