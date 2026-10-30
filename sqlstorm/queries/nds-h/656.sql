
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    si.s_name,
    si.TotalSupplyCost,
    CASE 
        WHEN si.PartCount > 10 THEN 'High Supplier'
        WHEN si.PartCount BETWEEN 5 AND 10 THEN 'Medium Supplier'
        ELSE 'Low Supplier'
    END AS SupplierCategory,
    od.o_orderkey,
    od.TotalOrderValue
FROM 
    SupplierInfo si
LEFT JOIN 
    OrderDetails od ON si.s_suppkey = od.o_custkey
WHERE 
    si.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM SupplierInfo)
    AND od.rn = 1
ORDER BY 
    si.TotalSupplyCost DESC, od.TotalOrderValue DESC;
