WITH  SalesCTE AS (
    SELECT 
        l_orderkey,
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rank
    FROM 
        lineitem
    GROUP BY 
        l_orderkey, l_partkey
    HAVING 
        SUM(l_extendedprice * (1 - l_discount)) > 0
),
RankedSales AS (
    SELECT 
        s.l_orderkey,
        s.l_partkey,
        s.total_sales,
        CASE 
            WHEN s.rank >= 3 THEN 'Top_3_Parts'
            ELSE 'Others'
        END AS part_rank
    FROM 
        SalesCTE s
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(r.total_sales), 0) AS total_ranked_sales,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    AVG(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS avg_supplier_acctbal
FROM 
    part p
LEFT JOIN 
    RankedSales r ON p.p_partkey = r.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 20.00 
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 1000.00)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_ranked_sales DESC;
