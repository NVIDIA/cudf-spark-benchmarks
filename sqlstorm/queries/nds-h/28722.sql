
SELECT 
    CONCAT(SUBSTRING(s.s_name, 1, 10), '...', ' from ', r.r_name) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE '%EUROPE%'
    AND o.o_orderstatus = 'O'
    AND l.l_discount > 0.05
GROUP BY 
    r.r_name, s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
