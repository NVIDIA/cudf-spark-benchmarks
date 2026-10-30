SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
    AND l.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC, avg_extended_price DESC
LIMIT 100;