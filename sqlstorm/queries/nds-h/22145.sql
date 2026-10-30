WITH ranked_lineitems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank_price,
        COALESCE(l.l_returnflag, 'N') AS return_flag_adj,
        CASE 
            WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END AS adjusted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
filtered AS (
    SELECT 
        r.r_name,
        SUM(rl.adjusted_price) AS total_adjusted_sales,
        COUNT(DISTINCT rl.l_orderkey) AS total_orders,
        AVG(rl.l_quantity) AS avg_quantity,
        COUNT(*) FILTER (WHERE rl.return_flag_adj = 'Y') AS return_count
    FROM 
        ranked_lineitems rl
    INNER JOIN 
        supplier s ON s.s_suppkey = rl.l_suppkey
    INNER JOIN 
        nation n ON n.n_nationkey = s.s_nationkey
    INNER JOIN 
        region r ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT rl.l_orderkey) > 5 
        AND SUM(CASE WHEN rl.return_flag_adj = 'Y' THEN 1 ELSE 0 END) < 0.1 * COUNT(*) 
),
final_result AS (
    SELECT 
        f.r_name,
        f.total_adjusted_sales,
        f.total_orders,
        f.avg_quantity,
        COALESCE(NULLIF(f.return_count, 0), NULL) AS safe_return_count
    FROM 
        filtered f
    WHERE 
        f.total_adjusted_sales IS NOT NULL 
        AND f.total_orders IS NOT NULL
)
SELECT 
    r.r_name,
    COALESCE(fr.total_adjusted_sales, 0) AS total_adjusted_sales,
    COALESCE(fr.total_orders, 0) AS total_orders,
    COALESCE(fr.avg_quantity, 0) AS avg_quantity,
    CASE 
        WHEN fr.safe_return_count IS NULL THEN 'No Returns'
        ELSE CAST(fr.safe_return_count AS STRING)
    END AS return_count_description
FROM 
    region r
LEFT JOIN 
    final_result fr ON r.r_name = fr.r_name
ORDER BY 
    total_adjusted_sales DESC, r.r_name;