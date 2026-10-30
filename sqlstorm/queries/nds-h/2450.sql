WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    WHERE 
        l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l_partkey
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        t.total_sales,
        s.supplier_count,
        s.avg_account_balance
    FROM 
        part p
    LEFT JOIN 
        TotalSales t ON p.p_partkey = t.l_partkey
    LEFT JOIN 
        SupplierStats s ON p.p_partkey = s.ps_partkey
    WHERE 
        t.total_sales IS NOT NULL AND
        t.total_sales > 10000
),
RankedParts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (ORDER BY p.total_sales DESC) AS sales_rank
    FROM 
        HighValueParts p
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    COALESCE(rp.total_sales, 0) AS total_sales,
    rp.supplier_count,
    rp.avg_account_balance
FROM 
    RankedParts rp
WHERE 
    rp.sales_rank <= 10
ORDER BY 
    rp.total_sales DESC;