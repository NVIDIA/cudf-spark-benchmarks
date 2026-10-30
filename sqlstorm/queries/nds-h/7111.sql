WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, s.s_acctbal,
           COUNT(ps.ps_partkey) AS supply_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.nation_name, s.s_acctbal, s.supply_count
    FROM SupplierInfo s
    WHERE s.supply_count > (
        SELECT AVG(supply_count) FROM SupplierInfo
    )
),
RevenueBySupplier AS (
    SELECT li.l_suppkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM lineitem li
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate < DATE '1997-01-01'
    GROUP BY li.l_suppkey
),
FinalSummary AS (
    SELECT ts.s_name, ts.nation_name, ts.s_acctbal, rb.total_revenue,
           (rb.total_revenue / ts.supply_count) AS avg_revenue_per_supply
    FROM TopSuppliers ts
    LEFT JOIN RevenueBySupplier rb ON ts.s_suppkey = rb.l_suppkey
)
SELECT *
FROM FinalSummary
ORDER BY avg_revenue_per_supply DESC
LIMIT 10;