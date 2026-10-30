
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT_WS(', ', c.c_name, CONCAT(c.c_address, ' (', c.c_phone, ')')) AS customer_details,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%BRASS%'
    AND o.o_orderstatus = 'F'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, c.c_address, c.c_phone, o.o_orderdate
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    revenue_rank, total_revenue DESC;
