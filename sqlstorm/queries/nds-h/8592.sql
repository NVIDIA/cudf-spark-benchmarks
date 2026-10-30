SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_quantity) AS total_quantity_sold,
    MAX(l.l_extendedprice) AS max_product_price
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
    r.r_name = 'NORTH AMERICA' AND
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    n.n_name, r.r_name
ORDER BY
    nation_name, region_name;