SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(lp.l_extendedprice) AS average_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND p.p_type LIKE '%green%'
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_available_quantity DESC, average_extended_price DESC
LIMIT 10;
