
SELECT
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN c.c_mktsegment = 'BUILDING' THEN 'Construction'
        WHEN c.c_mktsegment = 'FURNITURE' THEN 'Home Goods'
        ELSE 'Miscellaneous'
    END AS market_segment_category
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_brand LIKE 'Brand#%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, p.p_comment, c.c_mktsegment
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY
    total_revenue DESC;
