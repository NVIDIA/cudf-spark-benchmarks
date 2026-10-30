
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT_WS(' - ', p.p_mfgr, p.p_brand, p.p_type) AS product_details,
        SUM(l.l_quantity) AS total_quantity_ordered
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost, p.p_mfgr, p.p_brand, p.p_type
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        product_details,
        total_quantity_ordered,
        RANK() OVER (PARTITION BY supplier_name ORDER BY total_quantity_ordered DESC) AS rank
    FROM SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    product_details,
    total_quantity_ordered
FROM RankedSuppliers
WHERE rank <= 3
ORDER BY supplier_name, total_quantity_ordered DESC;
