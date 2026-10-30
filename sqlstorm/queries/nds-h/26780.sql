SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info, 
    SUBSTRING(n.n_name FROM 1 FOR 3) AS nation_abbr, 
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open' 
        ELSE 'Closed' 
    END AS order_status,
    COUNT(l.l_orderkey) AS total_orders, 
    SUM(l.l_extendedprice) AS total_revenue, 
    AVG(l.l_discount) AS average_discount
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
    p.p_name, supplier_info, nation_abbr, order_status
HAVING 
    AVG(l.l_discount) > 0.10
ORDER BY 
    total_revenue DESC
LIMIT 10;
