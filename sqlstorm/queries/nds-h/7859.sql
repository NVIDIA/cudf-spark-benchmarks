WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(o.o_totalprice) AS total_order_value, 
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
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        so.total_order_value, 
        so.order_count,
        RANK() OVER (ORDER BY so.total_order_value DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
),
RegionSummary AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(so.total_order_value) AS region_total_value,
        AVG(so.order_count) AS average_orders_per_supplier
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        TopSuppliers so ON n.n_nationkey = so.s_suppkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name, 
    rs.region_total_value, 
    rs.average_orders_per_supplier, 
    COUNT(ts.sales_rank) AS top_supplier_count
FROM 
    RegionSummary rs
JOIN 
    TopSuppliers ts ON rs.region_total_value > 1000000
GROUP BY 
    rs.r_name, rs.region_total_value, rs.average_orders_per_supplier
ORDER BY 
    rs.region_total_value DESC;
