SELECT 
    CONCAT(COALESCE(c.c_name, 'Unknown Customer'), ' - ', COALESCE(n.n_name, 'Unknown Nation')) AS customer_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT l.l_partkey) AS unique_parts_supplied
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY 
    customer_info
ORDER BY 
    total_revenue DESC
LIMIT 10;