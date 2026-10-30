SELECT
    p.p_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT('Total Revenue for ', p.p_name, ' supplied by ', s.s_name, ' for ', c.c_name) AS report_comment
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY
    total_revenue DESC
LIMIT 10;