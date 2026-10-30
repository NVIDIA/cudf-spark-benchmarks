
SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) AS total_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT(n.n_name, ' - ', s.s_name) AS supplier_region
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) > 10000
ORDER BY 
    total_orders DESC, total_price_after_discount DESC;
