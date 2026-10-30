
WITH SupplierDetails AS (
    SELECT 
        s.s_name AS SupplierName,
        s.s_address AS SupplierAddress,
        n.n_name AS Nation,
        p.p_name AS PartName,
        ps.ps_availqty AS AvailableQuantity,
        ps.ps_supplycost AS SupplyCost,
        SUBSTRING(p.p_comment, 1, 20) AS ShortComment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > 1000.00
), AggregatedSupply AS (
    SELECT 
        Nation,
        COUNT(*) AS SupplierCount,
        SUM(AvailableQuantity) AS TotalAvailableQuantity,
        SUM(SupplyCost) AS TotalSupplyCost
    FROM 
        SupplierDetails
    GROUP BY 
        Nation
)
SELECT 
    Nation,
    SupplierCount,
    TotalAvailableQuantity,
    TotalSupplyCost,
    CONCAT('Total Supply Cost for ', Nation, ' is ', CAST(TotalSupplyCost AS DECIMAL(10, 2))) AS CostSummary
FROM 
    AggregatedSupply
ORDER BY 
    TotalSupplyCost DESC;
