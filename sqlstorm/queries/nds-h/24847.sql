WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE 
        WHEN (ss.total_sales IS NULL OR ss.order_count IS NULL) THEN 'NO SALES'
        ELSE 'SALES RECORDED'
    END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ss.total_sales DESC) AS supplier_sales_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierSales ss ON ps.ps_partkey = ss.ps_partkey
JOIN 
    HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    (p.p_brand LIKE 'Brand%' OR p.p_name LIKE '%Special%') AND
    NOT EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'Y'
    )
ORDER BY 
    supplier_sales_rank, total_sales DESC;