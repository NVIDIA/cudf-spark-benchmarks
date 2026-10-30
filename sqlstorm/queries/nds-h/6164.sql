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
        rb.total_revenue,
        RANK() OVER (ORDER BY rb.total_revenue DESC) AS revenue_rank
    FROM 
        RevenueBySupplier rb
    JOIN 
        supplier s ON rb.s_suppkey = s.s_suppkey
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(rs.total_revenue) AS total_national_revenue
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
WHERE 
    rs.revenue_rank <= 10
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    total_national_revenue DESC;