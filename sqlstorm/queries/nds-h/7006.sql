
WITH SupplierOrders AS (
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
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders s
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(CASE WHEN rs.revenue_rank <= 10 THEN rs.total_revenue ELSE 0 END) AS top_10_revenue_sum
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON s.s_suppkey = rs.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    r.r_name, n.n_name;
