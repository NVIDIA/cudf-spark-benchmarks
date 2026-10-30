
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT_WS(' ', s.s_address, s.s_phone) AS supplier_info, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    LEFT(r.r_name, 5) AS region_short_name,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Quantity'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Quantity'
        ELSE 'Low Quantity' 
    END AS quantity_category,
    CHAR_LENGTH(p.p_comment) AS comment_length
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON c.c_custkey = o.o_custkey 
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey 
JOIN 
    region r ON r.r_regionkey = n.n_regionkey 
WHERE 
    p.p_retailprice > 20.00 
    AND s.s_acctbal > 0 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, s.s_phone, r.r_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC, quantity_category;
