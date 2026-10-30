
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TotalOrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price,
        COUNT(*) AS total_items
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
SuppliersWithLaterOrders AS (
    SELECT 
        rs.s_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS supplier_order_count
    FROM RankedSuppliers rs
    LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate > DATE '1998-10-01' - INTERVAL '1 YEAR'
    GROUP BY rs.s_suppkey
),
FinalBenchmark AS (
    SELECT 
        t.o_orderkey AS order_key,
        t.total_price,
        COALESCE(s.supplier_order_count, 0) AS supplier_orders_last_year,
        CASE 
            WHEN t.total_price IS NULL THEN 'No orders'
            WHEN t.total_price > 10000 THEN 'High value order'
            ELSE 'Regular order'
        END AS order_category
    FROM TotalOrderDetails t
    LEFT JOIN SuppliersWithLaterOrders s ON t.o_orderkey = s.supplier_order_count
)

SELECT 
    r.r_name AS region,
    MIN(f.total_price) AS min_total_price,
    MAX(f.total_price) AS max_total_price,
    AVG(f.total_price) AS avg_total_price,
    SUM(CASE WHEN f.order_category = 'High value order' THEN 1 ELSE 0 END) AS high_value_order_count,
    COUNT(DISTINCT f.order_key) AS unique_orders
FROM FinalBenchmark f
JOIN supplier s ON f.supplier_orders_last_year = s.s_suppkey 
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name NOT LIKE '%e%'
    AND f.total_price IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(*) > 10
ORDER BY avg_total_price DESC
LIMIT 5 
OFFSET 2;
