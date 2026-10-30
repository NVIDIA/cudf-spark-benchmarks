
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_suppkey,
        rs.s_name,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 5
)
SELECT 
    t.r_name,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    AVG(c.c_acctbal) AS AvgCustomerBalance
FROM 
    TopSuppliers t
JOIN 
    orders o ON t.s_suppkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    t.r_name
ORDER BY 
    Revenue DESC;
