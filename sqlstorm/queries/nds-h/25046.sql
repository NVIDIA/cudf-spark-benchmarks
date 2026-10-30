
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS customer_supplier_region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_discount) AS min_discount
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
    l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
    AND l.l_returnflag = 'N'
    AND l.l_linestatus = 'O'
GROUP BY 
    c.c_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
