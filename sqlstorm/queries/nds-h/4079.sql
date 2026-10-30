
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    COALESCE(ct.TotalOrders, 0) AS OrdersPlaced,
    COALESCE(ct.TotalSpent, 0) AS TotalSpent,
    COALESCE(rs.s_name, 'No Supplier') AS TopSupplier,
    COALESCE(rs.TotalCost, 0) AS SupplierCost
FROM 
    customer c
LEFT JOIN 
    CustomerTotalOrders ct ON c.c_custkey = ct.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.SupplierRank = 1 AND rs.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_quantity > 100
    )
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > 500.00
ORDER BY 
    TotalSpent DESC, OrdersPlaced DESC;
