WITH RegionSupplier AS (
    SELECT r.r_name AS region_name, s.s_name AS supplier_name, s.s_comment AS supplier_comment
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type, ps.ps_availqty,
           ps.ps_supplycost, s.s_name AS supplier_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedData AS (
    SELECT r.region_name, ps.p_brand, ps.p_type,
           COUNT(DISTINCT ps.supplier_name) AS unique_suppliers,
           SUM(ps.ps_availqty) AS total_available_quantity,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM PartSupplierDetails ps
    JOIN RegionSupplier r ON ps.supplier_name = r.supplier_name
    GROUP BY r.region_name, ps.p_brand, ps.p_type
)
SELECT region_name, p_brand, p_type, unique_suppliers, total_available_quantity,
       ROUND(average_supply_cost, 2) AS avg_supply_cost,
       (SELECT COUNT(*) FROM customer c WHERE c.c_mktsegment = 'BUILDING') AS building_customers
FROM AggregatedData
WHERE total_available_quantity > 1000
ORDER BY region_name, p_brand, p_type;
