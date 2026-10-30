
SELECT 
    p.p_name, 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    CASE 
        WHEN ps.ps_availqty < 100 THEN 'Low Stock'
        WHEN ps.ps_availqty BETWEEN 100 AND 500 THEN 'Moderate Stock'
        ELSE 'High Stock'
    END AS stock_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS return_status
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
GROUP BY 
    p.p_name, s.s_name, n.n_name, ps.ps_availqty, ps.ps_availqty
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 AND 
    CASE 
        WHEN ps.ps_availqty < 100 THEN 'Low Stock'
        WHEN ps.ps_availqty BETWEEN 100 AND 500 THEN 'Moderate Stock'
        ELSE 'High Stock'
    END = 'Moderate Stock'
ORDER BY 
    total_revenue DESC, p.p_name ASC;
