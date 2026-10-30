WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        l.l_partkey
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        COALESCE(MAX(ps.ps_availqty), 0) AS max_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    t.total_sales,
    sa.max_available,
    CASE 
        WHEN rs.supplier_rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier' 
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    TotalSales t ON p.p_partkey = t.l_partkey
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey AND rs.supplier_rank = 1
WHERE 
    (t.total_sales IS NOT NULL OR sa.max_available > 0)
    AND (p.p_retailprice BETWEEN 10.00 AND 100.00 OR p.p_comment IS NULL)
ORDER BY 
    t.total_sales DESC NULLS LAST, 
    sa.max_available DESC;