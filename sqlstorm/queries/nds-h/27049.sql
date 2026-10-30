
SELECT 
    CONCAT('Region: ', r.r_name, ' - Customer: ', c.c_name, ' (', c.c_address, ')') AS customer_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_sold
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
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    r.r_name, r.r_regionkey, c.c_custkey, c.c_name, c.c_address
ORDER BY 
    total_revenue DESC
LIMIT 10;
