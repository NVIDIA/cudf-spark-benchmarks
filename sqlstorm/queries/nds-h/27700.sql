WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name,
           p.p_name AS part_name,
           ps.ps_availqty,
           ps.ps_supplycost,
           CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, 
                  ' with availability of ', CAST(ps.ps_availqty AS STRING), 
                  ' and a supply cost of $', CAST(ps.ps_supplycost AS STRING)) AS supply_details
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT supplier_name,
           SUM(ps_availqty * ps_supplycost) AS total_supply_cost
    FROM SupplierParts
    GROUP BY supplier_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT ts.supplier_name,
       ROUND(ts.total_supply_cost, 2) AS total_supply_cost,
       STRING_AGG(sp.supply_details, '; ') AS detailed_supply_info
FROM TopSuppliers ts
JOIN SupplierParts sp ON ts.supplier_name = sp.supplier_name
GROUP BY ts.supplier_name, ts.total_supply_cost
ORDER BY ts.total_supply_cost DESC;
