
WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
HighValueOrders AS (
    SELECT o.c_custkey, SUM(o.o_totalprice) AS total_sales
    FROM CustomerOrders o
    WHERE o.order_rank <= 5
    GROUP BY o.c_custkey
),
TopNRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY nation_count DESC
    LIMIT 3
),
SupplierPartAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT
    c.c_name,
    r.r_name AS region_name,
    COALESCE(hv.total_sales, 0) AS total_sales,
    sp.total_avail_qty,
    sp.total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
FROM customer c
LEFT JOIN HighValueOrders hv ON c.c_custkey = hv.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN SupplierPartAggregates sp ON l.l_partkey = sp.ps_partkey
WHERE r.r_regionkey IN (SELECT r.r_regionkey FROM TopNRegions r)
AND (c.c_acctbal IS NULL OR c.c_acctbal > 1000)
GROUP BY c.c_name, r.r_name, hv.total_sales, sp.total_avail_qty, sp.total_supply_cost
HAVING COUNT(o.o_orderkey) > 10
ORDER BY total_sales DESC, order_count DESC;
