WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderDetail AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
NationRevenue AS (
    SELECT 
        n.n_nationkey, 
        SUM(cod.TotalRevenue) AS NationalRevenue
    FROM 
        nation n
    JOIN 
        customer cs ON n.n_nationkey = cs.c_nationkey
    JOIN 
        CustomerOrderDetail cod ON cs.c_custkey = cod.c_custkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name AS RegionName, 
    SUM(nr.NationalRevenue) AS TotalRevenueByRegion
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationRevenue nr ON n.n_nationkey = nr.n_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    TotalRevenueByRegion DESC
LIMIT 10;