WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT l_orderkey) AS order_count
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
    GROUP BY 
        l_partkey
),
RankedSales AS (
    SELECT 
        ts.l_partkey,
        ts.total_sales,
        ts.order_count,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
),
Suppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerCount AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
)

SELECT 
    r.r_name,
    n.n_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    cc.customer_count,
    s.s_name,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        ELSE CAST(rs.sales_rank AS STRING)
    END AS sales_rank_description
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    Suppliers s ON s.ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'Brand#23')
LEFT JOIN 
    RankedSales rs ON rs.l_partkey = s.ps_partkey
LEFT JOIN 
    CustomerCount cc ON n.n_nationkey = cc.c_nationkey
WHERE 
    r.r_name LIKE 'Asia%'
ORDER BY 
    total_sales DESC NULLS LAST;