WITH SupplierOrders AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        so.total_revenue,
        so.total_orders,
        so.avg_order_value,
        RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM
        SupplierOrders so
    JOIN
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT
    ts.s_suppkey,
    ts.s_name,
    ts.total_revenue,
    ts.total_orders,
    ts.avg_order_value
FROM
    TopSuppliers ts
WHERE
    ts.revenue_rank <= 10
ORDER BY
    ts.total_revenue DESC;