
WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_revenue,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders s
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.total_orders) AS avg_orders_per_supplier,
    SUM(rs.total_revenue) AS total_revenue_by_region
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.revenue_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_by_region DESC;
