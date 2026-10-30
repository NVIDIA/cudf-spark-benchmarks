WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderpriority
),
SupplierSummary AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
HighRevenueOrders AS (
    SELECT
        r.o_orderkey,
        r.total_revenue,
        s.s_suppkey,
        COALESCE(s.total_cost, 0) AS total_supplier_cost
    FROM
        RankedOrders r
    LEFT JOIN
        lineitem l ON r.o_orderkey = l.l_orderkey
    LEFT JOIN
        SupplierSummary s ON l.l_suppkey = s.s_suppkey
    WHERE
        r.revenue_rank <= 10
)
SELECT
    o.o_orderkey,
    o.total_revenue,
    o.total_supplier_cost,
    o.total_revenue - o.total_supplier_cost AS profit,
    CASE
        WHEN o.total_revenue - o.total_supplier_cost > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_or_loss
FROM
    HighRevenueOrders o
ORDER BY
    o.total_revenue DESC;