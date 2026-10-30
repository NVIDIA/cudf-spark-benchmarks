SELECT
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Comment: ', ps.ps_comment) AS detailed_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity
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
    s.s_name LIKE '%Supplier%'
    AND p.p_comment IS NOT NULL
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01'
GROUP BY
    s.s_name, p.p_name, ps.ps_comment
ORDER BY
    total_revenue DESC,
    average_quantity DESC
LIMIT 100;