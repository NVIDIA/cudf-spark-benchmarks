
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
ProcessedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(CASE WHEN l.l_returnflag = 'Y' THEN 1 ELSE 0 END) AS returned_items,
        COUNT(DISTINCT l.l_partkey) AS unique_items
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
SuppliersWithComment AS (
    SELECT 
        s.s_suppkey,
        s.s_comment,
        ROW_NUMBER() OVER (ORDER BY s.s_nationkey DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_comment IS NOT NULL AND LENGTH(s.s_comment) > 20
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(S1.s_name, 'No Supplier') AS supplier_name,
    COALESCE(S2.s_suppkey, -1) AS secondary_supplier,
    po.o_orderkey,
    po.o_totalprice AS total_price,
    po.returned_items,
    po.unique_items,
    (CASE 
        WHEN po.returned_items > 0 THEN 'Items returned'
        ELSE 'No returns'
    END) AS return_status,
    (SELECT COUNT(*) FROM lineitem li WHERE li.l_orderkey = po.o_orderkey AND li.l_discount > 0) AS discounted_items
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers S1 ON ps.ps_suppkey = S1.s_suppkey AND S1.rank = 1
LEFT JOIN 
    SuppliersWithComment S2 ON S2.s_suppkey = ps.ps_suppkey 
LEFT JOIN 
    ProcessedOrders po ON po.o_orderkey = ps.ps_partkey
WHERE 
    p.p_size NOT IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 1000) 
    AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey,
    total_price DESC NULLS LAST
LIMIT 100;
