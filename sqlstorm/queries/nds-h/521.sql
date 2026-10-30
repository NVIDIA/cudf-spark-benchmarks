
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.*,
        ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY part_count DESC) AS rank
    FROM SupplierDetails s
)
SELECT 
    COALESCE(ts.nation_name, 'Total') AS nation_name,
    COUNT(ts.s_suppkey) AS supplier_count,
    SUM(ts.s_acctbal) AS total_acctbal,
    AVG(ts.part_count) AS avg_parts_per_supplier
FROM TopSuppliers ts
FULL OUTER JOIN region r ON 1=1
WHERE ts.rank <= 3 OR ts.nation_name IS NULL
GROUP BY ts.nation_name
ORDER BY nation_name;
