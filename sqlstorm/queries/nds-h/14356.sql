
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
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
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC;
