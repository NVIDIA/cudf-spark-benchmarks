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
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerSpend AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.TotalOrderValue) AS TotalSpent
    FROM 
        customer c
    JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name AS CustomerName, 
    cs.TotalSpent AS TotalSpent, 
    ts.s_name AS TopSupplier, 
    ts.TotalSupplyCost AS SupplierCost
FROM 
    CustomerSpend cs
JOIN 
    TopSuppliers ts ON cs.TotalSpent > (SELECT AVG(TotalSupplyCost) FROM TopSuppliers)
ORDER BY 
    cs.TotalSpent DESC, 
    ts.TotalSupplyCost DESC;