SELECT 
    p.p_name AS part_name, 
    CONCAT(s.s_name, ' from ', SUBSTRING(s.s_address, 1, 15), '...') AS supplier_info, 
    SUM(l.l_quantity * (l.l_extendedprice * (1 - l.l_discount))) AS total_revenue,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand' 
    END AS demand_category
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'Asia'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address
ORDER BY 
    total_revenue DESC
LIMIT 10;