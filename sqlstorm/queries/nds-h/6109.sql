
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
),
TopOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue,
        r.revenue_rank
    FROM
        RankedOrders r
    WHERE
        r.revenue_rank <= 10
)
SELECT
    p.p_name,
    s.s_name,
    T.total_revenue
FROM
    TopOrders T
JOIN
    lineitem l ON T.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    s.s_acctbal > 1000.00
ORDER BY
    T.total_revenue DESC, s.s_name ASC
LIMIT 10;
