SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS average_retail_price,
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
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE 'S%' 
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    r.r_name,
    n.n_name,
    s.s_name,
    p.p_name
ORDER BY 
    total_available_quantity DESC, 
    total_supply_cost ASC
LIMIT 100;