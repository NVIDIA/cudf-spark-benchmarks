SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 
            (SUM(l.l_extendedprice) / COUNT(DISTINCT o.o_orderkey)) 
        ELSE 
            0 
    END AS avg_price_per_order,
    MAX(l.l_shipdate) AS last_ship_date,
    TRIM(CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name)) AS location_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 50 
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name
ORDER BY 
    total_quantity DESC 
LIMIT 10;