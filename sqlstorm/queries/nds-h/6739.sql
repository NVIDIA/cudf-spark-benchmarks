WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
SupplierRankings AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.r_name,
        ts.revenue,
        ROW_NUMBER() OVER (PARTITION BY ts.r_name ORDER BY ts.revenue DESC) AS rank
    FROM 
        TopSuppliers ts
)
SELECT 
    sr.r_name,
    sr.s_name,
    sr.revenue,
    rs.total_cost
FROM 
    SupplierRankings sr
JOIN 
    RankedSuppliers rs ON sr.s_suppkey = rs.s_suppkey
WHERE 
    sr.rank <= 5
ORDER BY 
    sr.r_name, sr.revenue DESC;