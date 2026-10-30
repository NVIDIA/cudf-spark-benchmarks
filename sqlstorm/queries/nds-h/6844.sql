
WITH region_sales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        o.o_orderdate >= '1997-01-01' AND
        o.o_orderdate < '1998-01-01'
    GROUP BY
        r.r_name
),
customer_sales AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_name
)
SELECT
    rs.region_name,
    COALESCE(cs.customer_name, 'Total') AS customer_name,
    SUM(cs.total_sales) AS total_customer_sales,
    rs.total_sales AS region_total_sales,
    (SUM(cs.total_sales) / NULLIF(rs.total_sales, 0)) * 100 AS customer_sales_percentage
FROM
    region_sales rs
LEFT JOIN
    customer_sales cs ON cs.total_sales IS NOT NULL
GROUP BY
    rs.region_name, cs.customer_name, rs.total_sales
ORDER BY
    rs.region_name, total_customer_sales DESC;
