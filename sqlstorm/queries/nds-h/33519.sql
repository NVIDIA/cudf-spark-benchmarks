WITH  nation_sales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS sale_rank
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        n.n_nationkey, n.n_name
),
sales_summary AS (
    SELECT 
        ns.nation_name,
        COALESCE(ns.total_sales, 0) AS total_sales,
        CASE 
            WHEN ns.total_sales = 0 THEN 'No Sales'
            ELSE 'Sales Made'
        END AS sales_status
    FROM 
        nation_sales ns
    UNION ALL
    SELECT 
        n.n_name AS nation_name,
        0 AS total_sales,
        'No Sales' AS sales_status
    FROM 
        nation n
    WHERE 
        n.n_nationkey NOT IN (SELECT n_nationkey FROM nation_sales)
),
ranked_sales AS (
    SELECT 
        nation_name,
        total_sales,
        sales_status,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.nation_name,
    r.total_sales,
    r.sales_status,
    r.sales_rank,
    CONCAT(CAST(r.total_sales AS STRING), ' USD') AS formatted_sales,
    CASE 
        WHEN r.total_sales IS NULL THEN 'Sales Data Unavailable'
        ELSE 'Sales Data Available'
    END AS availability_status
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
