WITH RegionalSales AS (
    SELECT 
        r_name,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT o_orderkey) AS order_count,
        AVG(c_acctbal) AS avg_customer_balance
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        r_name
),
TopRegions AS (
    SELECT
        r_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    tr.r_name,
    tr.total_sales,
    tr.sales_rank,
    CASE 
        WHEN tr.sales_rank <= 3 THEN 'Top Region'
        ELSE 'Other Region'
    END AS region_category,
    COALESCE(c.c_name, 'Unknown') AS customer_name
FROM 
    TopRegions tr
LEFT JOIN 
    orders o ON o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    tr.total_sales > (SELECT AVG(total_sales) FROM TopRegions)
ORDER BY 
    tr.sales_rank, tr.total_sales DESC;