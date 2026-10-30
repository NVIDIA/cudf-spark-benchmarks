WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_orders,
        so.total_revenue,
        so.avg_order_value,
        RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_orders,
    t.total_revenue,
    t.avg_order_value
FROM 
    TopSuppliers t
WHERE 
    t.revenue_rank <= 10
ORDER BY 
    t.total_revenue DESC;