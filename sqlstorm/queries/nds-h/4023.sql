WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_revenue,
        so.order_count,
        RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_revenue,
        rs.order_count,
        rs.revenue_rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.revenue_rank <= 5
)
SELECT 
    r.r_name AS region_name,
    SUM(ts.total_revenue) AS top_suppliers_revenue,
    AVG(ts.order_count) AS avg_orders_per_top_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    top_suppliers_revenue DESC;