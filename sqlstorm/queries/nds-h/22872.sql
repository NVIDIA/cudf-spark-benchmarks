
WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
SalesAndSuppliers AS (
    SELECT 
        rs.p_partkey,
        rs.p_name,
        sd.s_name,
        sd.nation_name,
        rs.total_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        partsupp ps ON rs.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE 
        rs.sales_rank <= 5 AND 
        (sd.s_acctbal BETWEEN 5000 AND 10000 OR sd.nation_name IS NULL)
)
SELECT 
    s.p_name,
    COALESCE(s.nation_name, 'Unknown') AS nation_or_unknown,
    s.total_sales,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High Sales'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    SalesAndSuppliers s
UNION ALL
SELECT 
    'Total Sales' AS p_name,
    NULL AS nation_or_unknown,
    SUM(s.total_sales) AS total_sales,
    NULL AS sales_category
FROM 
    SalesAndSuppliers s
GROUP BY 
    p_name
ORDER BY 
    total_sales DESC NULLS LAST;
