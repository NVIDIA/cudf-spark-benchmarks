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
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    rs.s_name AS supplier_name,
    rs.total_revenue,
    rs.order_count,
    rs.revenue_rank
FROM 
    RankedSuppliers rs
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (rs.total_revenue > (SELECT AVG(total_revenue) FROM SupplierOrders) OR rs.order_count > 5)
    AND r.r_name IS NOT NULL
ORDER BY 
    r.r_name, rs.total_revenue DESC;
