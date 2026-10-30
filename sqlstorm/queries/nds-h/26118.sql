
SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_shipdate) AS last_ship_date,
    LEAST(MAX(l.l_shipdate), MAX(o.o_orderdate)) AS comparison_date,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 
            (SUM(l.l_extendedprice) / COUNT(DISTINCT o.o_orderkey))
        ELSE 
            0 
    END AS avg_revenue_per_order
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
