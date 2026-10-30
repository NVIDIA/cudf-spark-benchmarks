WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    GROUP BY 
        r.r_name
), 
MaxSales AS (
    SELECT 
        region_name,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        RegionalSales
),
NationStatistics AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
RichCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE
            WHEN c.c_acctbal IS NULL THEN 'Unknown' 
            WHEN c.c_acctbal BETWEEN 1000 AND 2000 THEN 'Middle-Class' 
            WHEN c.c_acctbal > 2000 THEN 'High-Class' 
            ELSE 'Low-Class'
        END AS customer_classification
    FROM 
        customer c
    WHERE 
        COALESCE(c.c_acctbal, 0) > 1500
),
FinalResults AS (
    SELECT 
        rs.region_name,
        rs.total_sales,
        ns.n_name,
        ns.unique_suppliers,
        ns.avg_account_balance,
        rc.c_name AS rich_customer_name,
        rc.customer_classification
    FROM 
        MaxSales rs
    LEFT JOIN 
        NationStatistics ns ON rs.region_name = ns.n_name
    LEFT JOIN 
        RichCustomers rc ON ns.n_name = rc.c_name
)
SELECT 
    fr.region_name,
    fr.total_sales,
    fr.n_name,
    fr.unique_suppliers,
    fr.avg_account_balance,
    fr.rich_customer_name,
    fr.customer_classification,
    COALESCE(fr.total_sales / NULLIF(ns.avg_account_balance, 0), 0) AS sales_per_avg_balance
FROM 
    FinalResults fr
LEFT JOIN 
    NationStatistics ns ON fr.n_name = ns.n_name
WHERE 
    fr.total_sales < (SELECT AVG(total_sales) FROM MaxSales)
ORDER BY 
    fr.total_sales DESC, 
    fr.unique_suppliers ASC;
