WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * l.l_quantity) AS TotalCost,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        so.TotalCost, 
        so.TotalOrders,
        RANK() OVER (ORDER BY so.TotalCost DESC) AS SupplierRank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.TotalCost, 
    ts.TotalOrders
FROM 
    TopSuppliers ts
WHERE 
    ts.SupplierRank <= 10
ORDER BY 
    ts.TotalCost DESC;