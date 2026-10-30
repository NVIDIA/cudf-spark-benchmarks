WITH nation_summary AS (
    SELECT
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acct_balance,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        n.n_name
),
part_summary AS (
    SELECT
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_name
),
order_summary AS (
    SELECT
        o.o_orderstatus AS order_status,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY
        o.o_orderstatus
)
SELECT
    ns.nation_name,
    ns.total_acct_balance,
    ns.customer_count,
    ps.part_name,
    ps.total_available_qty,
    ps.avg_retail_price,
    os.order_status,
    os.total_revenue
FROM
    nation_summary ns
CROSS JOIN
    part_summary ps
CROSS JOIN
    order_summary os
WHERE
    ns.total_acct_balance > 10000.00
ORDER BY
    ns.total_acct_balance DESC,
    ps.avg_retail_price DESC,
    os.total_revenue DESC
LIMIT 100;