SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE 'EUROPE%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_returnflag = 'R'
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_supply_cost DESC
LIMIT 10;