WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(rs.TotalSupplyCost) AS NationalSupplyCost
    FROM 
        nation n
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE 
        rs.SupplierRank <= 3
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS Nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    h.NationalSupplyCost
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    HighValueNations h ON n.n_nationkey = h.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    n.n_name, h.NationalSupplyCost
ORDER BY 
    TotalRevenue DESC, h.NationalSupplyCost DESC;