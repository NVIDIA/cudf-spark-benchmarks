
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_sales,
    cs.order_count,
    s.parts_supplied,
    COALESCE(s.s_acctbal, 0) AS supplier_acctbal,
    CASE 
        WHEN cs.total_sales > 100000 THEN 'High'
        WHEN cs.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM 
    CustomerSales cs
LEFT JOIN 
    SupplierInfo s ON cs.c_custkey = s.s_suppkey
WHERE 
    cs.total_sales IS NOT NULL
    AND (s.parts_supplied IS NULL OR s.parts_supplied > 5)
    AND s.s_acctbal IS NOT NULL
UNION ALL
SELECT 
    o.o_orderkey,
    'Order Total' AS name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    NULL AS parts_supplied,
    NULL AS supplier_acctbal,
    NULL AS sales_category,
    NULL AS sales_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    o.o_orderkey
ORDER BY 
    total_sales DESC;
