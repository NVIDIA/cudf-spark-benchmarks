
WITH supplier_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
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
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
),
ranked_sales AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        supplier_sales
),
active_suppliers AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        s.s_suppkey,
        s.s_name
    FROM 
        nation ns
    LEFT JOIN 
        supplier s ON ns.n_nationkey = s.s_nationkey
    WHERE 
        s.s_suppkey IS NOT NULL
)

SELECT 
    r.r_name,
    COUNT(DISTINCT a.s_suppkey) AS supplier_count,
    COALESCE(SUM(r_sales.total_sales), 0) AS total_revenue,
    AVG(r_sales.order_count) AS average_orders
FROM 
    region r
LEFT JOIN 
    active_suppliers a ON a.n_nationkey = r.r_regionkey
LEFT JOIN 
    ranked_sales r_sales ON a.s_suppkey = r_sales.s_suppkey
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
