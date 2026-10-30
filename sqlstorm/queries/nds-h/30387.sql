
WITH  TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    ORDER BY 
        TotalCost DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS LineCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        r.r_name AS Region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    os.OrderRank,
    os.o_orderkey,
    os.o_orderdate,
    os.LineCount,
    os.TotalRevenue,
    sr.Region,
    ts.TotalCost
FROM 
    OrderSummary os
LEFT JOIN 
    SupplierRegion sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = os.o_orderkey)
JOIN 
    TopSuppliers ts ON sr.s_suppkey = ts.s_suppkey
WHERE 
    os.TotalRevenue > 50000 OR ts.TotalCost IS NOT NULL
ORDER BY 
    os.o_orderdate DESC, os.TotalRevenue DESC;
