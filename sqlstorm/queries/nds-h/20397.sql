WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rank_per_region,
        COALESCE(NULLIF(SUBSTRING(s.s_comment, 1, 10), ''), 'Unknown') AS short_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierOrderTotals AS (
    SELECT 
        rs.short_comment,
        fo.o_orderkey,
        fo.o_orderdate,
        SUM(l.l_extendedprice) AS total_extended_price,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
        MAX(l.l_tax) AS max_tax,
        MIN(l.l_discount) AS min_discount
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
    GROUP BY rs.short_comment, fo.o_orderkey, fo.o_orderdate
)
SELECT 
    s.short_comment,
    COUNT(DISTINCT s.o_orderkey) AS order_count,
    AVG(s.total_extended_price) AS avg_extended_price,
    STRING_AGG(s.short_comment, ', ') AS all_comments,
    CASE 
        WHEN SUM(s.lineitem_count) = 0 THEN NULL 
        ELSE (SUM(s.total_extended_price) / NULLIF(SUM(s.lineitem_count), 0)) 
    END AS avg_price_per_lineitem,
    MAX(s.max_tax) AS highest_tax,
    MIN(s.min_discount) AS lowest_discount
FROM SupplierOrderTotals s
WHERE s.total_extended_price IS NOT NULL
GROUP BY s.short_comment
HAVING COUNT(DISTINCT s.o_orderkey) > 1
ORDER BY s.short_comment ASC
LIMIT 10 OFFSET 10;
