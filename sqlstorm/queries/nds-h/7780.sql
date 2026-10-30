WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        co.OrderCount,
        co.TotalSpent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.TotalSpent > 10000
    ORDER BY 
        co.TotalSpent DESC
    LIMIT 10
)

SELECT 
    rs.s_name AS SupplierName,
    rs.TotalCost AS TotalCost,
    tc.c_name AS CustomerName,
    tc.OrderCount AS NumberOfOrders,
    tc.TotalSpent AS AmountSpent
FROM 
    RankedSuppliers rs
JOIN 
    TopCustomers tc ON rs.SupplierRank <= 3
ORDER BY 
    rs.TotalCost DESC, tc.TotalSpent DESC;
