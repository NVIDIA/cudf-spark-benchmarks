
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_nation_details,
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) AS average_price_per_line
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
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, n.n_name, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0 
ORDER BY 
    total_revenue DESC, total_quantity_sold DESC
LIMIT 10;
