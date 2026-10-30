SELECT 
    CONCAT(s.s_name, ' (', COUNT(DISTINCT l.l_orderkey), ' orders)') AS supplier_order_summary,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) AS average_price_per_line,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
WHERE 
    LENGTH(s.s_name) > 10 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-10-01'
GROUP BY 
    s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue_rank;