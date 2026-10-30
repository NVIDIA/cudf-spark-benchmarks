WITH  SalesCTE AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01'
    GROUP BY
        c.c_custkey, c.c_name
    
    UNION ALL
    
    SELECT
        s.s_suppkey AS c_custkey,
        s.s_name AS c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON l.l_partkey = ps.ps_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesCTE
)
SELECT
    r.r_name,
    SUM(rs.total_sales) AS region_total_sales,
    COUNT(DISTINCT rs.c_custkey) AS unique_customers,
    AVG(rs.total_sales) AS avg_sales_per_customer
FROM
    RankedSales rs
LEFT JOIN
    nation n ON rs.c_custkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    rs.total_sales IS NOT NULL
    AND r.r_name IS NOT NULL
GROUP BY
    r.r_name
HAVING
    AVG(rs.total_sales) > 1000
ORDER BY
    region_total_sales DESC
LIMIT 10 OFFSET 5;