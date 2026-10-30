
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.SupplierRank <= 3
)

SELECT 
    ps.ps_partkey,
    p.p_name,
    ts.s_name,
    ts.n_name AS Supplier_Nation,
    ts.TotalCost
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY 
    ts.TotalCost DESC, p.p_name ASC
LIMIT 50;
