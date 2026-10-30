WITH RevenueBySupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.total_revenue,
        RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        RevenueBySupplier r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.total_revenue > 0
)
SELECT 
    n.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_revenue
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    n.n_name, rs.total_revenue DESC;