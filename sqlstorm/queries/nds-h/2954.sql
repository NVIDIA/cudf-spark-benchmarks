WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        RANK() OVER (ORDER BY sr.TotalRevenue DESC) AS SupplierRank
    FROM 
        SupplierRevenue sr
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    COALESCE(c.OrderCount, 0) AS CustomerOrders,
    CASE 
        WHEN ts.SupplierRank <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS SupplierCategory
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrderCount c ON ts.s_suppkey = c.c_custkey 
WHERE 
    ts.s_name LIKE 'Supplier%'
ORDER BY 
    ts.SupplierRank, ts.s_suppkey;