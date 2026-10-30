WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        TotalSupplyCost
    FROM 
        RankedSuppliers s
    WHERE 
        s.SupplierRank = 1
),

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        COUNT(l.l_orderkey) AS LineCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    r.r_name AS Region,
    ts.s_name AS TopSupplier,
    SUM(od.Revenue) AS TotalRevenue,
    AVG(od.LineCount) AS AverageLineCount
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = ts.s_suppkey 
GROUP BY 
    r.r_name, ts.s_name
HAVING 
    SUM(od.Revenue) IS NOT NULL
ORDER BY 
    TotalRevenue DESC, Region;