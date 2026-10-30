WITH Supplier_Summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), Lineitem_Aggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region_name,
       SUM(CASE WHEN css.total_available_qty IS NOT NULL THEN css.total_supply_cost END) AS total_supplier_cost,
       SUM(CASE WHEN co.total_spent IS NOT NULL THEN co.total_spent END) AS total_customer_revenue,
       COUNT(DISTINCT la.l_orderkey) AS total_orders,
       SUM(la.revenue) AS total_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN Supplier_Summary css ON s.s_suppkey = css.s_suppkey
LEFT JOIN Customer_Orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN Lineitem_Aggregate la ON co.c_custkey = la.l_orderkey
GROUP BY r.r_name
ORDER BY region_name;