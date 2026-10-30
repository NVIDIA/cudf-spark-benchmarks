SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price
FROM
    nation n
JOIN
    region r ON n.n_regionkey = r.r_regionkey
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
    AND o.o_orderstatus = 'O'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_revenue DESC,
    nation_name ASC;