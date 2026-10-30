WITH SupplierProducts AS (
    SELECT s.s_name AS supplier_name, 
           p.p_name AS part_name,
           p.p_retailprice AS retail_price,
           ps.ps_availqty AS available_qty,
           (p.p_retailprice * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
NationSuppliers AS (
    SELECT n.n_name AS nation_name, 
           COUNT(DISTINCT sp.supplier_name) AS total_suppliers,
           SUM(sp.available_qty) AS total_available_qty,
           SUM(sp.total_value) AS total_inventory_value
    FROM SupplierProducts sp
    JOIN supplier s ON sp.supplier_name = s.s_name
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT ns.nation_name, 
       ns.total_suppliers, 
       ns.total_available_qty, 
       ns.total_inventory_value,
       CASE 
           WHEN ns.total_suppliers > 5 THEN 'High Supplier Presence'
           WHEN ns.total_suppliers BETWEEN 3 AND 5 THEN 'Moderate Supplier Presence'
           ELSE 'Low Supplier Presence'
       END AS supplier_presence
FROM NationSuppliers ns
ORDER BY ns.total_inventory_value DESC,
         ns.total_available_qty DESC;
