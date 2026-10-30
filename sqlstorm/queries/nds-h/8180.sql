WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        TotalSupplyCost DESC
    LIMIT 10
),
TopRegions AS (
    SELECT 
        n.n_regionkey, 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        TotalOrders DESC
    LIMIT 5
)
SELECT 
    tr.r_name AS Region_Name,
    ts.s_name AS Supplier_Name,
    ts.TotalSupplyCost,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue
FROM 
    TopRegions tr
JOIN 
    nation n ON tr.n_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    tr.r_name, ts.s_name, ts.TotalSupplyCost
ORDER BY 
    Total_Revenue DESC;
