WITH SupplierPartDetails AS (
    SELECT 
        s_name AS SupplierName,
        p_name AS PartName,
        ps_availqty AS AvailableQuantity,
        ps_supplycost AS SupplyCost,
        CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Available Qty: ', ps_availqty, ', Cost: $', ps_supplycost) AS DetailedInfo,
        ROW_NUMBER() OVER (PARTITION BY s_name ORDER BY ps_supplycost DESC) AS SupplierRank
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
    DetailedInfo
FROM 
    SupplierPartDetails
WHERE 
    SupplierRank <= 5
ORDER BY 
    SupplierName, 
    SupplyCost DESC;
