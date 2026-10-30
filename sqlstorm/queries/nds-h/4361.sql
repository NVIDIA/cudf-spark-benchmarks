
WITH regional_sales AS (
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        r.r_name
),
sales_priority AS (
    SELECT
        region_name,
        total_sales,
        order_count,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        regional_sales
    WHERE
        total_sales > (SELECT AVG(total_sales) FROM regional_sales)
)
SELECT
    sp.region_name,
    sp.total_sales,
    sp.order_count,
    CASE
        WHEN sp.sales_rank <= 3 THEN 'Top Region'
        WHEN sp.sales_rank <= 6 THEN 'Mid Region'
        ELSE 'Low Region'
    END AS sales_category
FROM
    sales_priority sp
WHERE
    sp.order_count > (SELECT AVG(order_count) FROM regional_sales)
UNION ALL
SELECT
    r.r_name AS region_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    'No Sales' AS sales_category
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
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
    o.o_orderdate < DATE '1997-01-01' OR o.o_orderdate >= DATE '1998-01-01'
GROUP BY
    r.r_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) = 0
ORDER BY
    total_sales DESC;
