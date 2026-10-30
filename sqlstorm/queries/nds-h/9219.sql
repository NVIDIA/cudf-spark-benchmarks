
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        n.n_name
    ORDER BY
        total_revenue DESC
    LIMIT 10
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    tn.n_name,
    ro.revenue
FROM
    RankedOrders ro
JOIN
    TopNations tn ON ro.revenue > 1000000
ORDER BY
    ro.rank, tn.total_revenue DESC;
