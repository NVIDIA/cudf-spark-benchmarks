WITH  OrderPriorities AS (
    SELECT o_orderkey, o_orderstatus, o_totalprice, o_orderdate, o_orderpriority,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rn
    FROM orders
),
CustomerRegions AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, r.r_name AS region_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name, n.n_name, r.r_name
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_name, COUNT(ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(sp.total_supply_value / NULLIF(sp.supplier_count, 0), 0) AS avg_supply_value
    FROM part p
    LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT cr.region_name, cr.nation_name, SUM(cr.total_spent) AS total_sales,
       COUNT(DISTINCT fp.p_partkey) AS distinct_parts_sold,
       AVG(fp.avg_supply_value) AS average_supply_value,
       MAX(OP.rn) AS max_priority
FROM CustomerRegions cr
LEFT JOIN lineitem li ON cr.c_custkey = li.l_orderkey
LEFT JOIN FilteredParts fp ON li.l_partkey = fp.p_partkey
LEFT JOIN OrderPriorities OP ON li.l_orderkey = OP.o_orderkey
WHERE cr.total_spent IS NOT NULL
GROUP BY cr.region_name, cr.nation_name
HAVING COUNT(fp.p_partkey) > 1
ORDER BY total_sales DESC, average_supply_value DESC;
