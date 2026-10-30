WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_availqty IS NOT NULL))
),
Sales AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        Sales s ON c.c_custkey = s.o_custkey
),
HighValueCustomers AS (
    SELECT 
        css.c_custkey,
        css.c_name,
        css.c_acctbal,
        COALESCE(css.total_sales, 0) AS total_sales
    FROM 
        CustomerSales css
    WHERE 
        css.sales_rank <= 10 OR (css.sales_rank IS NULL AND css.c_acctbal > 5000)
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
),
FinalSelection AS (
    SELECT 
        f.c_custkey,
        f.c_name,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        f.total_sales
    FROM 
        HighValueCustomers f
    JOIN 
        FilteredParts p ON f.total_sales > p.p_retailprice
)
SELECT 
    f.c_custkey,
    f.c_name,
    COUNT(DISTINCT f.p_partkey) AS part_count,
    SUM(CASE WHEN f.total_sales > 0 THEN f.total_sales ELSE NULL END) AS total_sales_example,
    AVG(NULLIF(f.p_retailprice, 0)) AS avg_part_price
FROM 
    FinalSelection f
GROUP BY 
    f.c_custkey, f.c_name
HAVING 
    COUNT(DISTINCT f.p_partkey) > 2 AND 
    AVG(NULLIF(f.p_retailprice, 0)) < 100
ORDER BY 
    total_sales_example DESC;
