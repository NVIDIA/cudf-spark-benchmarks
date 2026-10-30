WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS customer_order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
        LEFT OUTER JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tr.region_name,
    tr.total_sales,
    tr.sales_rank,
    cod.c_name,
    cod.customer_order_count,
    CASE 
        WHEN cod.customer_order_count IS NULL THEN 'No Orders'
        WHEN cod.total_spent > 1000 THEN 'High Roller'
        WHEN cod.total_spent IS NULL OR cod.total_spent <= 1000 THEN 'Casual Shopper'
    END AS customer_type
FROM 
    TopRegions tr
    LEFT JOIN CustomerOrderDetails cod ON (tr.sales_rank = cod.customer_order_count % 100) OR (tr.sales_rank IS NULL AND cod.customer_order_count IS NULL)
WHERE 
    tr.sales_rank <= 10
ORDER BY 
    tr.total_sales DESC NULLS LAST, 
    cod.c_name ASC;
