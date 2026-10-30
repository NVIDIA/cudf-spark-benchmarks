SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    c.c_name,
    s.s_name,
    p.p_brand,
    p.p_type,
    SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY
    c.c_name, s.s_name, p.p_brand, p.p_type, short_comment
ORDER BY
    total_revenue DESC
LIMIT 10;