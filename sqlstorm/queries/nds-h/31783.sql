
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000 

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > 5000 AND sh.level < 5
)

SELECT
    n.n_name AS nation_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', s.s_acctbal, ')'), ', ') AS suppliers_info
FROM
    nation n
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%Asia%')
    AND (l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31')
GROUP BY
    n.n_nationkey, p.p_partkey, n.n_name, p.p_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    nation_name, total_quantity DESC
LIMIT 10;
