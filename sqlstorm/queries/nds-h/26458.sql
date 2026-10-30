
SELECT 
    CONCAT_WS(', ', 
        p.p_name, 
        s.s_name, 
        c.c_name, 
        r.r_name
    ) AS full_description,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_quantity) AS max_quantity
FROM 
    part p
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    p.p_size BETWEEN 1 AND 50
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, p.p_partkey, s.s_suppkey, c.c_custkey, r.r_regionkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
