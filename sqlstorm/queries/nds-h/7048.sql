WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supplycost,
        RANK() OVER (PARTITION BY rs.nation_name ORDER BY rs.total_supplycost DESC) AS rnk
    FROM 
        RankedSuppliers rs
)
SELECT 
    ts.nation_name,
    ts.s_name,
    ts.total_supplycost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    ts.rnk <= 3
GROUP BY 
    ts.nation_name, ts.s_name, ts.total_supplycost
ORDER BY 
    ts.nation_name, ts.total_supplycost DESC;
