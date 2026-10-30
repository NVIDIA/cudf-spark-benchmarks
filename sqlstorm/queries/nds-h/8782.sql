
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY supplier_count DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT tr.r_name, COUNT(DISTINCT os.o_orderkey) AS total_orders, SUM(os.total_sales) AS total_revenue
    FROM TopRegions tr
    JOIN nation n ON tr.n_regionkey = n.n_regionkey
    JOIN OrderSummary os ON n.n_nationkey = os.o_orderkey -- corrected join clause
    JOIN RankedSuppliers rs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_acctbal > 10000
    )
    GROUP BY tr.r_name
)
SELECT * FROM FinalReport
ORDER BY total_revenue DESC;
