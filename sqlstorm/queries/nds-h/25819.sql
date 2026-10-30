
SELECT
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
GROUP BY
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC, avg_price ASC;
