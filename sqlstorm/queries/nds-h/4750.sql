
WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity_per_order,
        COUNT(DISTINCT l.l_returnflag) AS distinct_return_flags
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
CustomerRegionSummary AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS region_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
)
SELECT 
    sr.s_name,
    sr.total_revenue,
    cr.total_spent,
    cr.nation_name,
    CASE 
        WHEN cr.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status,
    CASE 
        WHEN sr.total_orders > 10 THEN 'High Volume Supplier'
        ELSE 'Low Volume Supplier'
    END AS supplier_volume
FROM 
    SupplierOrderSummary sr
LEFT JOIN 
    CustomerRegionSummary cr ON sr.s_suppkey = cr.c_custkey
WHERE 
    sr.total_revenue > (
        SELECT 
            AVG(total_revenue) 
        FROM 
            SupplierOrderSummary
    )
ORDER BY 
    sr.total_revenue DESC, 
    cr.region_rank ASC
LIMIT 50;
