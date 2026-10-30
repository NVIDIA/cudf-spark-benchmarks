WITH  SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM partsupp
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS suppliers_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT pp.p_partkey, pp.p_name, pp.num_suppliers, pp.total_supply_cost,
           CASE WHEN pp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierDetails) 
                THEN 'Above Average' 
                ELSE 'Below Average' END AS cost_comparison
    FROM PartSupplierDetails pp
)
SELECT rs.n_name AS region_name,
       SUM(co.order_count) AS total_orders,
       SUM(co.total_spent) AS total_revenue,
       SUM(fp.total_supply_cost) AS total_supply_cost,
       SUM(CASE WHEN fp.cost_comparison = 'Above Average' THEN 1 ELSE 0 END) AS costly_parts
FROM RegionSupplier rs
LEFT JOIN CustomerOrders co ON (rs.n_nationkey = co.c_custkey OR rs.n_nationkey IS NULL)
LEFT JOIN FilteredParts fp ON (fp.p_partkey IN (SELECT ps_partkey FROM SupplyCostCTE WHERE rnk = 1 AND ps_supplycost IS NOT NULL))
GROUP BY rs.n_name
HAVING SUM(co.total_spent) IS NOT NULL AND 
       SUM(fp.total_supply_cost) < (SELECT SUM(ps_supplycost) FROM partsupp) * 0.1
ORDER BY total_orders DESC NULLS LAST;
