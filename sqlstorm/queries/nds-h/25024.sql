SELECT 
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 15) AS abbreviated_comment,
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS latest_ship_date
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
WHERE 
    p.p_size BETWEEN 5 AND 20
    AND s.s_acctbal > 1000
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, p.p_comment, s.s_name, s.s_address
ORDER BY 
    total_revenue DESC, part_name ASC
LIMIT 10;