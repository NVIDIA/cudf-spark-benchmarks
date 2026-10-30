WITH  CustomerOrders AS (
    SELECT o.o_orderkey, c.c_custkey, c.c_name, o.o_totalprice, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    sp.total_supply_cost,
    nr.r_name AS supplier_region,
    COALESCE(sp.p_name, 'Unknown Part') AS part_name
FROM CustomerOrders co
LEFT JOIN SupplierParts sp ON co.o_orderkey = sp.ps_partkey
LEFT JOIN NationRegion nr ON co.c_custkey = nr.n_nationkey
WHERE co.recent_order = 1
  AND (sp.total_supply_cost IS NOT NULL OR sp.total_supply_cost > 1000)
ORDER BY co.o_totalprice DESC, nr.r_name, co.c_name;
