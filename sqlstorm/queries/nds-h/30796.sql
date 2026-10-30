
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey,
        s_acctbal,
        CAST(s_name AS VARCHAR(255)) AS hierarchy_path
    FROM 
        supplier
    WHERE 
        s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CAST(CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS VARCHAR(255))
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal < sh.s_acctbal
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
ExcessiveLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_line_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        COUNT(*) > 10
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    CASE 
        WHEN SUM(l.l_discount) >= 0.1 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_bracket
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31')
    AND (o.o_orderstatus IN ('F', 'P') OR o.o_orderkey IS NOT NULL)
    AND p.p_container IS NOT NULL
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    total_sales DESC
LIMIT 100;
