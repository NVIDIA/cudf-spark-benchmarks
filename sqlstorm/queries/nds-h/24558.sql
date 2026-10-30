
WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
sales_ranked AS (
    SELECT 
        region_name, 
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM regional_sales
),
customer_status AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal > 1000 THEN 'High Value'
            WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        COUNT(o.o_orderkey) AS orders_placed
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
final_report AS (
    SELECT 
        sr.region_name,
        sr.total_sales,
        cs.customer_value,
        cs.orders_placed,
        ROW_NUMBER() OVER (PARTITION BY sr.region_name ORDER BY cs.orders_placed DESC) AS rn
    FROM sales_ranked sr
    LEFT JOIN customer_status cs ON sr.region_name = (
        SELECT 
            r.r_name 
        FROM region r 
        JOIN nation n ON r.r_regionkey = n.n_regionkey 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        JOIN lineitem l ON p.p_partkey = l.l_partkey 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderkey IN (SELECT DISTINCT o_orderkey FROM orders)
        LIMIT 1
    )
)
SELECT 
    region_name,
    total_sales,
    customer_value,
    orders_placed
FROM final_report
WHERE rn <= 5
ORDER BY region_name, total_sales DESC, customer_value;
