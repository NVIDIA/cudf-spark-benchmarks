SELECT
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', 
           SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE 0 END), ' of ', 
           p.p_name) AS supply_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS latest_order_date
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name, n.n_name, p.p_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_revenue DESC
LIMIT 10;