WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_quantity) AS total_quantity, 
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.total_quantity, 
        s.total_revenue,
        DENSE_RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders s
)
SELECT 
    r.r_name AS region, 
    ns.n_name AS nation, 
    rs.s_name AS supplier_name, 
    rs.total_quantity, 
    rs.total_revenue
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
ORDER BY 
    r.r_name, 
    ns.n_name, 
    rs.total_revenue DESC;