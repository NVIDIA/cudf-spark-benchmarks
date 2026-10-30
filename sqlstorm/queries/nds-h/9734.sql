WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
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
        SUM(o.o_totalprice) AS TotalOrderValue,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_name, 
        sp.TotalSupplyCost,
        sp.UniquePartsSupplied
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    ORDER BY 
        sp.TotalSupplyCost DESC 
    LIMIT 5
),
TopCustomers AS (
    SELECT 
        co.c_name, 
        co.TotalOrderValue,
        co.TotalOrders
    FROM 
        CustomerOrders co
    ORDER BY 
        co.TotalOrderValue DESC 
    LIMIT 5
)

SELECT 
    ts.s_name AS SupplierName, 
    ts.TotalSupplyCost AS SupplierCost,
    tc.c_name AS CustomerName, 
    tc.TotalOrderValue AS CustomerValue
FROM 
    TopSuppliers ts
CROSS JOIN 
    TopCustomers tc
ORDER BY 
    ts.TotalSupplyCost DESC, tc.TotalOrderValue DESC;