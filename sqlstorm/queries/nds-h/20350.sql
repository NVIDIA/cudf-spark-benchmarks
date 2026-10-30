WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
), CustomerInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        p.p_partkey, 
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, p.p_partkey
), HighValueCustomers AS (
    SELECT 
        ci.c_custkey, 
        ci.c_name
    FROM 
        CustomerInfo ci
    WHERE 
        ci.TotalSpent > (
            SELECT 
                AVG(TotalSpent) 
            FROM 
                CustomerInfo
        )
), ClosedOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderstatus, 
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.o_orderstatus = 'F' AND r.OrderRank <= 5
)
SELECT 
    c.c_name AS CustomerName,
    sp.TotalSupplyCost AS TotalSupplyCost,
    COALESCE(ho.o_totalprice, 0) AS LastClosedOrderAmount,
    CASE 
        WHEN sp.TotalSupplyCost > 1000 THEN 'High Supplier Cost'
        WHEN sp.TotalSupplyCost IS NULL THEN 'No Supply Cost Found'
        ELSE 'Normal Supplier Cost'
    END AS CostCategory
FROM 
    HighValueCustomers c
LEFT JOIN 
    SupplierParts sp ON c.c_custkey = sp.s_suppkey
LEFT JOIN 
    ClosedOrders ho ON c.c_custkey = ho.o_orderkey
WHERE 
    (sp.TotalSupplyCost IS NULL OR sp.TotalSupplyCost > 500)
ORDER BY 
    c.c_name, TotalSupplyCost DESC
LIMIT 10;
