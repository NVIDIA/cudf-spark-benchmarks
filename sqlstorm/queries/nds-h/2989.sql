WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        r.r_name
),
CumulativeSales AS (
    SELECT
        region_name,
        total_sales,
        order_count,
        SUM(total_sales) OVER (ORDER BY region_name) AS cumulative_sales
    FROM
        RegionalSales
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        cumulative_sales
    FROM
        CumulativeSales
    WHERE
        total_sales > (
            SELECT AVG(total_sales) FROM CumulativeSales
        )
)
SELECT
    tr.region_name,
    tr.total_sales,
    tr.cumulative_sales,
    CASE 
        WHEN tr.total_sales >= 100000 THEN 'High' 
        WHEN tr.total_sales >= 50000 THEN 'Medium' 
        ELSE 'Low' 
    END AS sales_category
FROM
    TopRegions tr
LEFT JOIN
    (SELECT DISTINCT c_nationkey, c_acctbal, c_mktsegment
     FROM customer
     WHERE c_acctbal IS NOT NULL 
       AND c_mktsegment IS NOT NULL) AS cust ON cust.c_nationkey = (
           SELECT n_nationkey FROM nation WHERE n_name = 'USA'
           LIMIT 1
       )
ORDER BY
    tr.total_sales DESC, tr.region_name;