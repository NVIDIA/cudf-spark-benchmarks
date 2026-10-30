WITH  regional_sales AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        n.n_nationkey, n.n_name
    UNION ALL
    SELECT
        r.r_regionkey,
        CONCAT('Total for ', n.n_name) AS n_name,
        SUM(s.s_acctbal) AS total_sales,
        COUNT(DISTINCT s.s_suppkey) AS order_count
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_regionkey, n.n_name
),
sales_summary AS (
    SELECT
        n_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        regional_sales
)
SELECT
    r.n_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales' 
        WHEN s.order_count > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM
    nation r
LEFT JOIN
    sales_summary s ON r.n_name = s.n_name
WHERE
    r.n_nationkey IN (SELECT DISTINCT n_nationkey FROM supplier WHERE s_acctbal > 5000)
ORDER BY
    s.total_sales DESC NULLS LAST;