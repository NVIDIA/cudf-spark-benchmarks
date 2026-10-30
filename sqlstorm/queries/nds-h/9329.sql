WITH SupplierOrders AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM SupplierOrders
)
SELECT
    r.r_name AS region,
    ns.n_name AS nation,
    ts.s_name AS supplier_name,
    ts.total_orders,
    ts.total_revenue,
    ts.avg_quantity
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation ns ON s.s_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
WHERE ts.revenue_rank <= 10
ORDER BY region, nation, total_revenue DESC;
