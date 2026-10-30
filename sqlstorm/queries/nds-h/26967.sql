SELECT 
    CONCAT(s.s_name, ' from ', c.c_name, ' in ', n.n_name) AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
WHERE 
    l.l_shipmode IN ('AIR', 'LAND')
    AND s.s_comment LIKE '%reliable%'
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    supplier_info
ORDER BY 
    total_sales DESC
LIMIT 10;