SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01'
    AND l.l_shipdate >= '1996-01-01' 
    AND l.l_shipdate < '1997-01-01'
GROUP BY 
    n.n_name, r.r_name, s.s_name
HAVING 
    SUM(ps.ps_supplycost * l.l_quantity) > 100000
ORDER BY 
    total_supply_cost DESC, average_supply_cost DESC;