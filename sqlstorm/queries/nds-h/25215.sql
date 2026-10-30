
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Revenue: ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS CHAR(20))) AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipmode IN ('TRUCK', 'SHIP')
    AND o.o_orderdate >= '1996-01-01'
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    revenue DESC;
