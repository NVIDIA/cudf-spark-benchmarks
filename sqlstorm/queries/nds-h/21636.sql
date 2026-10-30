
WITH  supply_rank AS (
    SELECT
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rn
    FROM partsupp
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
national_supply AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
aggregated_data AS (
    SELECT
        n.n_name,
        SUM(COALESCE(c.net_sales, 0)) AS total_sales,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM national_supply n
    LEFT JOIN customer_orders c ON n.n_nationkey = c.c_custkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
final_results AS (
    SELECT
        a.n_name,
        a.total_sales,
        a.supplier_count,
        CASE 
            WHEN a.total_sales IS NULL THEN 'No Sales'
            WHEN a.total_sales < 10000 THEN 'Low Sales'
            ELSE 'High Sales'
        END AS sales_category,
        RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
    FROM aggregated_data a
    WHERE a.supplier_count > 0
)
SELECT
    f.n_name,
    f.total_sales,
    f.supplier_count,
    f.sales_category,
    f.sales_rank,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')) AS regional_suppliers_count
FROM final_results f
WHERE f.sales_rank <= 10
ORDER BY f.total_sales DESC
LIMIT 5;
