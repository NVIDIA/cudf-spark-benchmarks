WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 0 AND o.o_orderdate >= '1996-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_orders,
        so.total_revenue,
        so.avg_order_price,
        RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(rs.s_suppkey) AS supplier_count,
    SUM(rs.total_revenue) AS total_nation_revenue
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
WHERE 
    rs.revenue_rank <= 5
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    total_nation_revenue DESC;