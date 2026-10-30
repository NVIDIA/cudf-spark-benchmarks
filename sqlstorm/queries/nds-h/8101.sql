SELECT
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(c.c_acctbal) AS avg_customer_balance,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM
    nation n
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
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
GROUP BY
    n.n_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY
    total_sales DESC;