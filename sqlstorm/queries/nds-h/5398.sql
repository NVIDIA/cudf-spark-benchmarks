SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND n.n_name IN ('USA', 'Canada')
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;