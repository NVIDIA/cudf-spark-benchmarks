SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_value
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    r.r_name LIKE 'N%' 
    AND o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_revenue DESC, customer_count DESC;