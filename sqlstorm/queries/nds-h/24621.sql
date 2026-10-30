
WITH RankedCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
),
HighValueSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(ps_supplycost * ps_availqty)
        FROM partsupp ps
    )
),
OrderLineStats AS (
    SELECT l.l_orderkey,
           COUNT(*) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
FilteredOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_totalprice,
           COALESCE(ols.total_lines, 0) AS total_lines,
           COALESCE(ols.total_revenue, 0) AS total_revenue
    FROM orders o
    LEFT JOIN OrderLineStats ols ON o.o_orderkey = ols.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
)
SELECT r.r_name,
       COUNT(DISTINCT rc.c_custkey) AS unique_customers,
       AVG(f.total_revenue) AS avg_revenue,
       SUM(f.total_lines) AS total_lines
FROM RankedCustomers rc
JOIN FilteredOrders f ON rc.c_custkey = f.o_custkey
JOIN nation n ON rc.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN HighValueSuppliers hvs ON hvs.total_cost > (
       SELECT AVG(total_cost) * 0.9 FROM HighValueSuppliers
)
WHERE rc.rnk = 1 AND hvs.s_suppkey IS NULL
GROUP BY r.r_name
HAVING SUM(f.total_revenue) > (
    SELECT AVG(total_revenue) FROM FilteredOrders
)
ORDER BY unique_customers DESC, avg_revenue DESC
LIMIT 10;
