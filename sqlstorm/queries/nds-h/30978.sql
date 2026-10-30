WITH  Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) as sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
Filtered_Sales AS (
    SELECT 
        s.o_orderkey,
        s.total_sales,
        s.o_orderdate,
        CASE 
            WHEN s.total_sales > 1000 THEN 'High'
            WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        Sales_CTE s
    WHERE 
        s.sales_rank = 1
),
Supplier_Summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(SUM(fs.total_sales), 0) AS total_sales,
    ss.total_avail_qty,
    ss.supplier_count,
    CASE 
        WHEN SUM(fs.total_sales) IS NULL THEN 'No Sales'
        WHEN SUM(fs.total_sales) > 2000 THEN 'Very High Sales'
        ELSE 'Sales Data Available'
    END AS sales_status
FROM 
    part p
LEFT JOIN 
    Filtered_Sales fs ON p.p_partkey = fs.o_orderkey
JOIN 
    Supplier_Summary ss ON p.p_partkey = ss.ps_partkey
WHERE 
    p.p_size IN (10, 20, 30) AND
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_regionkey = 1
        )
    )
GROUP BY 
    p.p_name, ss.total_avail_qty, ss.supplier_count
ORDER BY 
    total_sales DESC NULLS LAST;
