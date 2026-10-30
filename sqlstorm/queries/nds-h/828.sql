WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey 
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey 
    WHERE 
        l.l_returnflag = 'N' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_revenue,
        s.order_count,
        s.avg_quantity,
        RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderStats s
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(rs.total_revenue), 0) AS total_suppliers_revenue,
    AVG(rs.avg_quantity) AS avg_quantity_per_supplier
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey 
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    nation_count DESC, total_suppliers_revenue DESC;