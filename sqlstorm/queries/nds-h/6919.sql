SELECT
    n.n_name AS nation_name,
    sum(o.o_totalprice) AS total_revenue,
    count(DISTINCT c.c_custkey) AS unique_customers,
    avg(l.l_extendedprice - l.l_discount) AS avg_price_after_discount,
    count(DISTINCT l.l_orderkey) AS total_orders
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND
    p.p_size IN (10, 20, 30)
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;