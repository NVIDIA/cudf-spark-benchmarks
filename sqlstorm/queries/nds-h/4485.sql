WITH ranked_suppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
high_value_orders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_partkey) AS part_count,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    CASE
        WHEN SUM(l.l_tax) > 0 THEN 'Tax Applied'
        ELSE 'No Tax'
    END AS tax_status
FROM
    lineitem l
LEFT JOIN
    high_value_orders hvo ON l.l_orderkey = hvo.o_orderkey
LEFT JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    l.l_quantity > 0 AND
    hvo.o_orderdate BETWEEN '1997-01-01' AND cast('1998-10-01' as date)
GROUP BY
    l.l_orderkey, n.n_name
HAVING
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY
    total_revenue DESC
LIMIT 10;