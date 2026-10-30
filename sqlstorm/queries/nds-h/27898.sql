
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderdate AS order_date,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Volume'
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    CONCAT(p.p_brand, ' - ', p.p_type, ' - ', p.p_container) AS part_details,
    SUBSTRING(s.s_comment, 1, 30) AS supplier_comment_preview
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE o.o_orderstatus = 'O'
AND l.l_shipdate > '1997-01-01'
AND p.p_size IN (8, 12, 16)
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderdate,
    p.p_brand, 
    p.p_type, 
    p.p_container, 
    s.s_comment
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC, order_date ASC;
