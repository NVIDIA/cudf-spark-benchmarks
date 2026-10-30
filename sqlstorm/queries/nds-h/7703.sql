WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_available_qty,
        ss.avg_supply_cost,
        ss.total_revenue,
        RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
)
SELECT
    ts.s_name,
    ts.total_available_qty,
    ts.avg_supply_cost,
    ts.total_revenue
FROM TopSuppliers ts
WHERE ts.revenue_rank <= 10
ORDER BY ts.total_revenue DESC;
