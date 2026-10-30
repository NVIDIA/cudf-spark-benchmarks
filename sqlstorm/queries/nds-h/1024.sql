
WITH SupplierTotals AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS items_count,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
NationRegion AS (
    SELECT n.n_nationkey,
           n.n_name,
           r.r_regionkey,
           r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.r_name AS region_name,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(COALESCE(ct.total_spent, 0)) AS total_spent_by_customers,
       SUM(st.total_supply_cost) AS total_suppliers_cost,
       AVG(ls.avg_quantity) AS avg_item_quantity_per_order,
       MIN(ls.total_revenue) AS min_revenue_per_order,
       MAX(ls.total_revenue) AS max_revenue_per_order
FROM CustomerOrders ct
FULL OUTER JOIN SupplierTotals st ON ct.order_count > 10
LEFT JOIN LineItemSummary ls ON ct.total_spent > 1000 AND ct.c_custkey = ls.l_orderkey
JOIN NationRegion n ON ct.c_custkey = n.n_nationkey
JOIN customer c ON ct.c_custkey = c.c_custkey -- Add missing join to customer
GROUP BY n.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_spent_by_customers DESC, unique_customers DESC;
