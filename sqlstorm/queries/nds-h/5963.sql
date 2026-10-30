WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        rs.s_name,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = rs.s_suppkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    ts.nation_name,
    ts.s_name,
    ts.total_supplycost
FROM 
    TopSuppliers ts
ORDER BY 
    ts.nation_name, ts.total_supplycost DESC;
