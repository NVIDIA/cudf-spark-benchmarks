
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN o.o_orderstatus = 'F' THEN o.o_totalprice 
        ELSE NULL 
    END) AS avg_filled_order_price,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND n.n_name <> 'USA'
GROUP BY 
    p.p_name, p.p_comment, r.r_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 10;
