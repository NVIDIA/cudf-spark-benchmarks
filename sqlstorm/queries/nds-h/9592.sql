WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT
        c_mktsegment,
        SUM(total_revenue) AS segment_revenue
    FROM
        RankedOrders
    WHERE
        revenue_rank <= 5
    GROUP BY
        c_mktsegment
)
SELECT
    ts.c_mktsegment,
    ts.segment_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.total_revenue) AS avg_order_revenue
FROM
    TopSegments ts
JOIN
    RankedOrders ro ON ts.c_mktsegment = ro.c_mktsegment
GROUP BY
    ts.c_mktsegment, ts.segment_revenue
ORDER BY
    ts.segment_revenue DESC;
