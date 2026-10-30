SELECT
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    o.o_orderdate AS order_date,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date
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
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    c.c_mktsegment = 'BUILDING'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_revenue DESC, last_ship_date DESC;