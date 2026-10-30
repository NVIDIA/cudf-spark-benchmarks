
WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT nh.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM NationHierarchy nh
    JOIN nation n ON nh.n_nationkey = n.n_regionkey
), 
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierPerformance AS (
    SELECT s.s_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost, COUNT(DISTINCT p.p_partkey) AS part_count,
           ROW_NUMBER() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
)
SELECT n.n_name, COALESCE(SUM(os.total_sales), 0) AS total_sales,
       COALESCE(SUM(sp.avg_supply_cost * sp.part_count), 0) AS avg_cost_per_part,
       MAX(sp.supplier_rank) AS max_supplier_rank
FROM nation n
LEFT JOIN OrderSummary os ON n.n_nationkey = os.o_orderkey
LEFT JOIN SupplierPerformance sp ON n.n_nationkey = sp.s_suppkey
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'N%')
GROUP BY n.n_name
HAVING COALESCE(SUM(os.total_sales), 0) > 50000
ORDER BY total_sales DESC, n.n_name
LIMIT 10 OFFSET 5;
