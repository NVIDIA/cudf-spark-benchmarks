
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderpriority, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 month'
), 
SupplierLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    GROUP BY l.l_orderkey
), 
FinalReport AS (
    SELECT c.c_name, SUM(oli.net_revenue) AS total_revenue,
           MAX(os.o_orderpriority) AS top_priority_order,
           COUNT(DISTINCT oli.l_orderkey) AS order_count,
           r.r_name
    FROM customer c
    JOIN SupplierLineItems oli ON c.c_custkey = oli.l_orderkey
    JOIN OrderStats os ON oli.l_orderkey = os.o_orderkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY c.c_name, r.r_name
    HAVING SUM(oli.net_revenue) IS NOT NULL
)
SELECT 
    fr.c_name,
    fr.total_revenue,
    fr.top_priority_order,
    CASE 
        WHEN fr.order_count > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM FinalReport fr
WHERE fr.total_revenue > 5000
ORDER BY fr.total_revenue DESC;
