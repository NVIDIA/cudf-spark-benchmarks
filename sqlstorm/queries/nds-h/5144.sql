
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        orders o ON ps.ps_partkey = o.o_orderkey  -- corrected join condition
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY
        n.n_name
),
TotalRevenue AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM
        RankedOrders
    WHERE
        order_rank <= 5
)
SELECT
    t.n_name,
    t.order_count,
    tr.total_revenue
FROM
    TopNations t,
    TotalRevenue tr
ORDER BY
    t.order_count DESC, tr.total_revenue DESC;
