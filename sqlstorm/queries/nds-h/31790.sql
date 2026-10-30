
WITH  ProductSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
HighSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.total_sales
    FROM 
        part p
    LEFT JOIN 
        ProductSales ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.total_sales IS NOT NULL
), 
NationSupplier AS (
    SELECT 
        n.n_name,
        s.s_suppkey,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, s.s_suppkey
), 
TotalRevenue AS (
    SELECT 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
)

SELECT 
    H.p_name,
    H.p_brand,
    H.p_retailprice,
    COALESCE(NS.total_acctbal, 0) AS supplier_acct_balance,
    ROUND(H.total_sales - COALESCE(NS.total_acctbal, 0), 2) AS net_sales_after_supplier_balance,
    CASE 
        WHEN H.total_sales > (SELECT total_revenue FROM TotalRevenue) THEN 'High Sales'
        ELSE 'Normal Sales'
    END AS sales_category
FROM 
    HighSales H
LEFT JOIN 
    NationSupplier NS ON H.p_partkey = NS.s_suppkey
WHERE 
    H.total_sales IS NOT NULL
ORDER BY 
    H.total_sales DESC
LIMIT 50;
