WITH SupplierOrderData AS (
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
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderData s
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    COALESCE(ts2.total_revenue, 0) AS recorded_revenue,
    ts.revenue_rank,
    CASE 
        WHEN ts.revenue_rank <= 5 THEN 'Top 5 Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    TopSuppliers ts
LEFT JOIN 
    SupplierOrderData ts2 ON ts.s_suppkey = ts2.s_suppkey
WHERE 
    ts.revenue_rank <= 10
ORDER BY 
    ts.revenue_rank;
