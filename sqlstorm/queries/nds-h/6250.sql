WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        n.n_regionkey
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, 
        c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    r.r_name AS Region, 
    ts.c_name AS TopCustomer, 
    ts.TotalSpent, 
    rs.s_name AS BestSupplier, 
    rs.TotalSupplyCost
FROM 
    RankedSuppliers rs
JOIN 
    region r ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'))
JOIN 
    TopCustomers ts ON rs.SupplierRank = 1 AND ts.TotalSpent >= 1000
WHERE 
    rs.SupplierRank <= 5
ORDER BY 
    r.r_name, ts.TotalSpent DESC, rs.TotalSupplyCost DESC;