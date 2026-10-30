WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT s.*, ROW_NUMBER() OVER (ORDER BY TotalSupplyCost DESC) AS Rank
    FROM RankedSuppliers s
    WHERE TotalSupplyCost > 10000
),
TopSuppliers AS (
    SELECT f.s_suppkey, f.s_name, f.TotalSupplyCost
    FROM FilteredSuppliers f
    WHERE f.Rank <= 10
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, SUM(ps.ps_availqty) AS TotalAvailable
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
)
SELECT 
    ts.s_name AS SupplierName,
    pd.p_name AS PartName,
    pd.p_mfgr AS Manufacturer,
    pd.TotalAvailable AS TotalAvailableQuantity,
    CONCAT('Supplier: ', ts.s_name, ', Part: ', pd.p_name, ', Manufacturer: ', pd.p_mfgr) AS Description,
    CASE 
        WHEN pd.TotalAvailable > 500 THEN 'High Availability'
        WHEN pd.TotalAvailable BETWEEN 100 AND 500 THEN 'Medium Availability'
        ELSE 'Low Availability'
    END AS AvailabilityStatus
FROM TopSuppliers ts
JOIN PartDetails pd ON ts.s_suppkey = pd.p_partkey
ORDER BY SupplierName, TotalAvailableQuantity DESC;
