
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS average_supplier_balance,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Order: ', o.o_orderkey) AS detailed_info
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    l.l_shipdate > DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1997-12-31' 
    AND s.s_comment LIKE '%quality%'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000 
ORDER BY 
    revenue DESC 
LIMIT 10;
