
WITH  OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
), 
SupplierCTE AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
LineItemCTE AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM lineitem l
    GROUP BY l.l_orderkey
), 
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
FilteredOrders AS (
    SELECT o.o_orderkey, SUM(l.total_revenue) AS total_revenue
    FROM OrderCTE o
    JOIN LineItemCTE l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    p.p_partkey, p.p_name, p.p_brand, 
    COALESCE(f.total_revenue, 0) AS total_ordered_revenue, 
    COALESCE(s.total_supplycost, 0) AS total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY COALESCE(f.total_revenue, 0) DESC) AS part_rank
FROM part p
LEFT JOIN FilteredOrders f ON p.p_partkey = f.o_orderkey
LEFT JOIN SupplierCTE s ON p.p_partkey = s.ps_partkey
WHERE p.p_retailprice > 100.00 
  AND EXTRACT(MONTH FROM DATE '1998-10-01') = 10
  AND s.total_availqty IS NOT NULL
ORDER BY part_rank
LIMIT 50;
