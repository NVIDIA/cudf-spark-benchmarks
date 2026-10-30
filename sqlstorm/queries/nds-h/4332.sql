
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        AVG(s.s_acctbal) AS AvgAccountBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    p.p_name,
    p.SupplierCount,
    s.TotalSupplyValue,
    c.TotalOrders,
    c.TotalSpent,
    CASE 
        WHEN c.TotalSpent IS NULL OR c.TotalSpent = 0 THEN 'No Orders'
        WHEN c.TotalSpent < 1000 THEN 'Low Spender'
        ELSE 'High Spender'
    END AS SpendingCategory,
    ROW_NUMBER() OVER (PARTITION BY 
        CASE 
            WHEN c.TotalSpent IS NULL OR c.TotalSpent = 0 THEN 'No Orders'
            WHEN c.TotalSpent < 1000 THEN 'Low Spender'
            ELSE 'High Spender'
        END 
        ORDER BY s.TotalSupplyValue DESC) AS Rank
FROM 
    PartSupplierInfo p
LEFT JOIN 
    SupplierStats s ON p.p_partkey = s.s_suppkey
LEFT JOIN 
    CustomerOrders c ON s.s_suppkey = c.c_custkey
WHERE 
    p.TotalAvailableQuantity > 100
ORDER BY 
    p.SupplierCount DESC,
    SpendingCategory,
    Rank;
