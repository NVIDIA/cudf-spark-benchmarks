
WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS TotalSuppliers,
        SUM(s_acctbal) AS TotalAccountBalance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c_nationkey,
        COUNT(DISTINCT o_custkey) AS TotalCustomers,
        SUM(o_totalprice) AS TotalOrderValue,
        COUNT(DISTINCT o_orderkey) AS TotalOrders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c_nationkey
),
PartSupplyStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name,
    COALESCE(ss.TotalSuppliers, 0) AS TotalSuppliers,
    COALESCE(cs.TotalCustomers, 0) AS TotalCustomers,
    COALESCE(cs.TotalOrders, 0) AS TotalOrders,
    COALESCE(cs.TotalOrderValue, 0) AS TotalOrderValue,
    SUM(pss.TotalAvailableQuantity) AS OverallAvailableQuantity,
    SUM(pss.TotalSupplyCost) AS OverallSupplyCost
FROM 
    region r
LEFT JOIN 
    SupplierStats ss ON r.r_regionkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrderStats cs ON r.r_regionkey = cs.c_nationkey
LEFT JOIN 
    PartSupplyStats pss ON cs.c_nationkey = pss.ps_partkey
GROUP BY 
    r.r_name, ss.TotalSuppliers, cs.TotalCustomers, cs.TotalOrders, cs.TotalOrderValue
ORDER BY 
    TotalOrderValue DESC, TotalSuppliers DESC;
