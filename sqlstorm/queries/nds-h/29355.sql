SELECT 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    LEFT(r.r_name, 3) AS region_prefix,
    CASE
        WHEN o.o_orderstatus = 'F' THEN 'Filled'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_desc
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_type LIKE 'BRASS%'
GROUP BY 
    supplier_part, customer_name, region_prefix, order_status_desc
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 100;