WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        ps.ps_availqty AS available_quantity,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0 AND 
        p.p_size BETWEEN 10 AND 50
), 
AggregatedData AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS part_count,
        SUM(retail_price) AS total_retail_value,
        SUM(available_quantity) AS total_available_quantity,
        MAX(total_supply_cost) AS max_supply_cost
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    part_count,
    total_retail_value,
    total_available_quantity,
    max_supply_cost,
    CASE 
        WHEN part_count >= 10 THEN 'High Supplier'
        WHEN part_count BETWEEN 5 AND 9 THEN 'Medium Supplier'
        ELSE 'Low Supplier' 
    END AS supplier_category
FROM 
    AggregatedData
ORDER BY 
    total_retail_value DESC, 
    supplier_name;
