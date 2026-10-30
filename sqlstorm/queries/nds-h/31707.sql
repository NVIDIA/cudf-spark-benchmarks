
WITH  sales_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 0
),
part_sales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_orders,
        p.p_brand,
        p.p_mfgr
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_mfgr
),
nations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
final_result AS (
    SELECT
        ss.c_name,
        ps.p_name,
        ps.total_sales AS part_sales,
        ns.supplier_count,
        ns.region_name,
        ss.c_custkey,
        ps.p_partkey,
        ns.n_nationkey
    FROM sales_summary ss
    JOIN part_sales ps ON ss.total_sales > 1000 AND ss.rn <= 5
    JOIN nations ns ON ss.c_custkey = ns.n_nationkey
)

SELECT 
    c.c_name,
    p.p_name,
    COALESCE(p.total_sales, 0) AS total_sales,
    CASE 
        WHEN ns.supplier_count IS NULL THEN 'No Suppliers'
        ELSE CAST(ns.supplier_count AS STRING)
    END AS supplier_count,
    ns.region_name
FROM final_result
FULL OUTER JOIN customer c ON c.c_custkey = final_result.c_custkey
FULL OUTER JOIN part_sales p ON p.p_partkey = final_result.p_partkey
FULL OUTER JOIN nations ns ON ns.n_nationkey = final_result.n_nationkey
WHERE 
    (p.total_sales IS NOT NULL OR c.c_custkey IS NULL)
    AND (ns.supplier_count > 1 OR ns.supplier_count IS NULL)
ORDER BY total_sales DESC, c.c_name, p.p_name;
