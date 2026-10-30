
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    rs.s_name AS SupplierName,
    rs.TotalSupplyCost,
    hvc.c_name AS HighValueCustomerName,
    hvc.OrderCount
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON hvc.OrderCount > 5
WHERE 
    rs.rnk <= 5
ORDER BY 
    rs.TotalSupplyCost DESC, hvc.OrderCount DESC;
