WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
),
SupplierStats AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RegionalSales AS (
    SELECT n.n_regionkey,
           SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY n.n_regionkey
),
LineItemSummary AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT p.p_name,
       COALESCE(r.total_sales, 0) AS total_region_sales,
       COALESCE(l.total_revenue, 0) AS total_revenue,
       s.total_available,
       s.avg_supply_cost,
       CASE 
           WHEN s.avg_supply_cost IS NULL THEN 'Unknown'
           ELSE CASE 
               WHEN s.avg_supply_cost > 100 THEN 'Expensive'
               WHEN s.avg_supply_cost <= 100 AND s.avg_supply_cost > 50 THEN 'Moderate'
               ELSE 'Cheap'
           END
       END AS cost_category,
       COUNT(DISTINCT oo.o_orderkey) AS orders_in_year
FROM part p
LEFT JOIN LineItemSummary l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierStats s ON p.p_partkey = s.part_count
LEFT JOIN RegionalSales r ON p.p_partkey = r.n_regionkey
LEFT JOIN RankedOrders oo ON oo.o_orderkey = l.order_count
WHERE p.p_retailprice > 50.00
GROUP BY p.p_name, r.total_sales, l.total_revenue, s.total_available, s.avg_supply_cost
ORDER BY p.p_name, total_region_sales DESC, total_revenue DESC;