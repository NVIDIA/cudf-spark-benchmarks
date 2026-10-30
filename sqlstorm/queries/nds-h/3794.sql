WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.rank <= 3
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
        INNER JOIN customer c ON o.o_custkey = c.c_custkey
        INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
), 
SupplierPartCounts AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    o.o_orderkey,
    o.c_name,
    o.total_price,
    sp.part_count,
    COALESCE(r.r_name, 'Unknown Region') AS supplier_region,
    CASE 
        WHEN o.total_price > 1000 THEN 'High Value'
        WHEN o.total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM 
    OrderDetails o
    LEFT JOIN SupplierPartCounts sp ON o.o_orderkey = sp.ps_suppkey
    LEFT JOIN supplier s ON s.s_suppkey = sp.ps_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.total_price IS NOT NULL 
    AND o.line_item_count > 5
ORDER BY 
    total_price DESC
LIMIT 10;