WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 500.00 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
RankedSuppliers AS (
    SELECT 
        s.*, 
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
    FROM 
        SupplierOrders s
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_quantity,
        r.total_revenue,
        r.revenue_rank,
        r.quantity_rank,
        CASE 
            WHEN r.revenue_rank <= 10 THEN 'Top Revenue Supplier' 
            ELSE 'Non-Top Revenue Supplier' 
        END AS supplier_category
    FROM 
        RankedSuppliers r
    WHERE 
        r.total_revenue IS NOT NULL
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_quantity,
    t.total_revenue,
    t.supplier_category,
    COALESCE(n.n_name, 'Unknown') AS nation_name
FROM 
    TopSuppliers t
LEFT JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    t.quantity_rank <= 15 AND 
    t.total_quantity IS NOT NULL
ORDER BY 
    t.total_revenue DESC, t.total_quantity ASC;
