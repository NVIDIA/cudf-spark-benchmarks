WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RankedSuppliers AS (
    SELECT 
        sr.*, 
        RANK() OVER (PARTITION BY sr.s_nationkey ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    n.n_name AS nation_name, 
    rs.s_name AS supplier_name, 
    rs.total_revenue, 
    rs.order_count
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    n.n_name, rs.total_revenue DESC;
