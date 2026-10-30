SELECT 
    CONCAT_WS(' - ', 
        CONCAT('Supplier: ', s_name), 
        CONCAT('Part: ', p_name), 
        CONCAT('Region: ', r_name), 
        CONCAT('Nation: ', n_name), 
        CONCAT('Customer: ', c_name)
    ) AS benchmark_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
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
    r.r_name LIKE '%NORTH%'
AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, r.r_name, n.n_name, c.c_name
ORDER BY 
    total_revenue DESC
LIMIT 10;