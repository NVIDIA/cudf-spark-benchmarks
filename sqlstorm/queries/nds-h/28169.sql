
SELECT
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(s.s_acctbal) AS max_supplier_balance,
    MIN(l.l_discount) AS min_discount,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS location_details
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
GROUP BY
    p.p_name,
    s.s_name,
    r.r_name,
    n.n_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC, 
    avg_price DESC;
