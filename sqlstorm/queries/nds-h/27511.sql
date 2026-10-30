
SELECT 
    CONCAT(s.s_name, ' | ', p.p_name, ' | ', l.l_shipmode) AS supplier_part_shipmode,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(CASE 
            WHEN l.l_returnflag = 'R' THEN 1 
            ELSE 0 
        END) AS has_returns
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE 'PROMO%'
    AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    s.s_name, p.p_name, l.l_shipmode
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, distinct_orders DESC;
