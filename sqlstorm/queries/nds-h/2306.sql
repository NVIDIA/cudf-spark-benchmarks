
WITH OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(*) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_available,
        ss.part_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_available DESC) AS rnk
    FROM SupplierStats ss
    WHERE ss.total_available > 0
)
SELECT 
    ot.o_orderkey,
    ot.total_amount,
    fs.s_suppkey,
    fs.total_available,
    fs.part_count
FROM OrderTotals ot
FULL OUTER JOIN FilteredSuppliers fs ON ot.item_count = fs.part_count
LEFT JOIN supplier s ON fs.s_suppkey = s.s_suppkey
WHERE (fs.part_count IS NOT NULL OR ot.total_amount IS NULL)
AND (fs.total_available BETWEEN 100 AND 1000 OR fs.s_suppkey IS NULL)
ORDER BY ot.total_amount DESC NULLS LAST, fs.total_available ASC;
