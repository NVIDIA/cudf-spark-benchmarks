WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS SupplierName, 
        p.p_name AS PartName, 
        ps.ps_availqty AS AvailableQuantity, 
        ps.ps_supplycost AS SupplyCost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS SupplyInfo,
        CASE 
            WHEN ps.ps_availqty < 10 THEN 'Low Stock' 
            WHEN ps.ps_availqty >= 10 AND ps.ps_availqty < 50 THEN 'Medium Stock' 
            ELSE 'High Stock' 
        END AS StockLevel
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    SupplierName,
    PartName,
    AvailableQuantity,
    SupplyCost,
    SupplyInfo,
    StockLevel,
    CASE 
        WHEN SupplyCost < 20.00 THEN 'Economical'
        WHEN SupplyCost BETWEEN 20.00 AND 50.00 THEN 'Moderate'
        ELSE 'Expensive'
    END AS CostCategory
FROM 
    SupplierPartDetails
WHERE 
    StockLevel = 'Low Stock'
ORDER BY 
    SupplyCost DESC, 
    SupplierName ASC;
