SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' (', n.n_nationkey, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE 'Cog%'
    AND l.l_returnflag = 'R' 
    AND l.l_shipdate >= DATE '1996-01-01'
GROUP BY 
    s.s_name, n.n_name, n.n_nationkey
ORDER BY 
    total_revenue DESC
LIMIT 10;