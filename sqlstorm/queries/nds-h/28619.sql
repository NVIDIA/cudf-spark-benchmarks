
WITH SupplierPartInfo AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity, 
        ps.ps_supplycost AS supply_cost, 
        CONCAT_WS(' ', s.s_address, LEFT(s.s_comment, 30)) AS supplier_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
AggregatedInfo AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS num_parts,
        SUM(available_quantity) AS total_quantity,
        AVG(supply_cost) AS avg_cost,
        RANK() OVER (ORDER BY SUM(available_quantity) DESC) AS rank_by_quantity
    FROM 
        SupplierPartInfo
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name, 
    num_parts, 
    total_quantity, 
    ROUND(avg_cost, 2) AS average_supply_cost,
    CASE 
        WHEN rank_by_quantity <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category
FROM 
    AggregatedInfo
WHERE 
    total_quantity > 100
ORDER BY 
    total_quantity DESC, 
    supplier_name;
