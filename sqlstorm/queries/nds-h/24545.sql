WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts,
        AVG(s.s_acctbal) AS AvgAccountBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.TotalCost,
        sd.UniqueParts,
        sd.AvgAccountBalance
    FROM 
        SupplierDetails sd
    WHERE 
        sd.TotalCost > (
            SELECT 
                AVG(TotalCost) 
            FROM 
                SupplierDetails
        )
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    HVS.s_name AS HighValueSupplier,
    COS.TotalOrders,
    COS.TotalSpent,
    FRE.TotalSpent / NULLIF(COS.TotalOrders, 0) AS AvgSpentPerOrder,
    CASE 
        WHEN HVS.AvgAccountBalance IS NULL THEN 'No Balance Info'
        ELSE CAST(HVS.AvgAccountBalance AS STRING)
    END AS AvgSupplierBalance
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueSuppliers HVS ON n.n_nationkey = HVS.s_suppkey
LEFT JOIN 
    CustomerOrderStats COS ON n.n_nationkey = COS.c_custkey
CROSS JOIN 
    (SELECT SUM(o_totalprice) AS TotalSpent FROM orders) FRE
WHERE 
    (HVS.UniqueParts IS NULL OR HVS.UniqueParts > 5)
    AND (FRE.TotalSpent IS NOT NULL OR COS.TotalSpent < 10000)
ORDER BY 
    n.n_name, r.r_name, COS.TotalSpent DESC;
