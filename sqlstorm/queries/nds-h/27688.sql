SELECT 
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price_after_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name,
    MAX(o.o_orderdate) AS last_order_date
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
    r.r_name LIKE 'N%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_price_after_discount DESC, unique_customers ASC;