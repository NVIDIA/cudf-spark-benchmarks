SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(s.s_comment, 1, 25) AS short_comment,
    CONCAT(r.r_name, ' ', n.n_name) AS region_nation,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Quantity'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Quantity'
        ELSE 'Low Quantity'
    END AS quantity_category
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 25.00 AND 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, short_comment, region_nation
ORDER BY 
    total_revenue DESC, order_count ASC
LIMIT 10;