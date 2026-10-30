WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        AVG(o.o_totalprice) AS AvgOrderPrice
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS SupplierName,
    rs.TotalSupplyCost,
    co.c_name AS CustomerName,
    co.OrderCount,
    co.AvgOrderPrice,
    CASE 
        WHEN co.OrderCount > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS CustomerStatus
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    CustomerOrders co ON rs.rn = co.c_custkey
WHERE 
    (rs.TotalSupplyCost IS NOT NULL OR co.OrderCount IS NOT NULL)
ORDER BY 
    SupplierName, CustomerName;
