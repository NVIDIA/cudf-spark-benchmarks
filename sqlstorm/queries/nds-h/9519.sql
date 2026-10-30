SELECT
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_quantity) AS avg_line_quantity,
    MAX(s.s_acctbal) AS max_supplier_account_balance
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
WHERE
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_shipdate >= DATE '1997-01-01'
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;