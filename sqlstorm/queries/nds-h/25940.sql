SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING(ps.ps_comment, 1, 50) AS partial_comment
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.c_acctbal > 1000.00 
    AND l.l_shipmode IN ('SHIP', 'FOB')
GROUP BY 
    c.c_name, s.s_name, r.r_name, ps.ps_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_sales DESC
LIMIT 10;
