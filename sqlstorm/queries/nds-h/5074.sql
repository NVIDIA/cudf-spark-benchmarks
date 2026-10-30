WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sum(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY sum(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name LIKE 'Asia%')
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        n.n_name AS Nation, 
        rs.s_name AS SupplierName, 
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    WHERE 
        rs.Rank <= 3
)
SELECT 
    t.Nation,
    COUNT(t.SupplierName) AS SupplierCount,
    SUM(t.TotalCost) AS TotalSuppliersCost
FROM 
    TopSuppliers t
GROUP BY 
    t.Nation
ORDER BY 
    TotalSuppliersCost DESC;
