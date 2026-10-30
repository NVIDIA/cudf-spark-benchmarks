WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS OrdersCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        sd.TotalCost, 
        sd.TotalOrders,
        ROW_NUMBER() OVER (ORDER BY sd.TotalCost DESC) AS SupplierRank
    FROM 
        SupplierDetails sd
),
QualifiedCustomers AS (
    SELECT 
        cd.c_custkey, 
        cd.c_name, 
        cd.OrdersCount, 
        cd.TotalSpent,
        RANK() OVER (ORDER BY cd.TotalSpent DESC) AS SpendingRank
    FROM 
        CustomerDetails cd
    WHERE 
        cd.TotalSpent > 1000
)
SELECT 
    qs.c_name AS CustomerName, 
    qs.TotalSpent AS CustomerTotalSpent,
    rs.s_name AS SupplierName, 
    rs.TotalCost AS SupplierTotalCost
FROM 
    QualifiedCustomers qs
JOIN 
    RankedSuppliers rs ON rs.SupplierRank <= 10
WHERE 
    rs.TotalOrders > 1
ORDER BY 
    qs.TotalSpent DESC, 
    rs.TotalCost DESC;
