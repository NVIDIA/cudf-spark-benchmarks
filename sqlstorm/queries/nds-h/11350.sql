SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM
    part AS p
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
