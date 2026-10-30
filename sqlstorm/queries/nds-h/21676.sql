WITH  nation_ranks AS (
    SELECT n_regionkey, n_name, ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) AS rank
    FROM nation
),
part_sales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY p.p_partkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        (SUM(ps.ps_supplycost) / NULLIF(COUNT(ps.ps_partkey), 0)) AS avg_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
sales_summary AS (
    SELECT 
        ps.p_partkey,
        ps.total_sales,
        COALESCE(si.avg_supplycost, 0) AS avg_supplycost,
        CASE 
            WHEN ps.order_count > 5 THEN 'High Volume'
            WHEN ps.order_count BETWEEN 1 AND 5 THEN 'Moderate Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM part_sales ps
    LEFT JOIN supplier_info si ON ps.p_partkey = si.part_count
),
final_output AS (
    SELECT 
        ns.n_name,
        ss.p_partkey, 
        ss.total_sales,
        ss.avg_supplycost,
        ss.volume_category,
        ROW_NUMBER() OVER (PARTITION BY ns.n_regionkey ORDER BY ss.total_sales DESC) as rank_by_sales
    FROM sales_summary ss
    JOIN nation_ranks ns ON ss.p_partkey IS NOT NULL
)
SELECT 
    fo.n_name, 
    fo.p_partkey,
    fo.total_sales, 
    fo.avg_supplycost,
    fo.volume_category
FROM final_output fo
WHERE fo.rank_by_sales < 10
ORDER BY fo.n_name ASC, fo.total_sales DESC;

