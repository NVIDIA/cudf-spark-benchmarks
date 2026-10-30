WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        rs.s_suppkey,
        rs.s_name,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.SupplierRank <= 5
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ts.RegionName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_quantity) AS TotalQuantity,
    AVG(l.l_discount) AS AverageDiscount
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    ts.RegionName
ORDER BY 
    TotalOrders DESC;