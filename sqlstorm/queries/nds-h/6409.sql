
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), TotalSales AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), SupplierContribution AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        ts.TotalSpent AS CustomerTotalSpent
    FROM 
        RankedSuppliers rs
    JOIN 
        lineitem l ON l.l_suppkey = rs.s_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        TotalSales ts ON o.o_custkey = ts.c_custkey
    WHERE 
        rs.Rank <= 5
)
SELECT 
    s.s_suppkey, 
    s.s_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS Returns
FROM 
    SupplierContribution s
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    s.s_suppkey, s.s_name
ORDER BY 
    Revenue DESC
LIMIT 10;
