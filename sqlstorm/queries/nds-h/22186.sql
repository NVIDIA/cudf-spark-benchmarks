WITH MonthlySales AS (
    SELECT 
        EXTRACT(MONTH FROM o.o_orderdate) AS month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY EXTRACT(MONTH FROM o.o_orderdate)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.part_count
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.part_count > (SELECT AVG(part_count) FROM SupplierStats)
),
RankedSales AS (
    SELECT 
        month,
        total_sales,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM MonthlySales
)

SELECT 
    r.month,
    CASE 
        WHEN r.sales_rank <= 3 THEN 'Top Sales Month'
        ELSE 'Regular Month'
    END AS sales_category,
    COALESCE(t.s_name, 'No Supplier') AS supplier_name,
    ll.* 
FROM RankedSales r
LEFT JOIN TopSuppliers t ON r.month = EXTRACT(MONTH FROM cast('1998-10-01' as date)) AND t.part_count IS NOT NULL
FULL OUTER JOIN lineitem ll ON r.month = EXTRACT(MONTH FROM ll.l_shipdate)
WHERE 
    (ll.l_returnflag IS NULL OR ll.l_returnflag <> 'R')
    AND (ll.l_discount IS NOT NULL AND ll.l_discount > 0.05)
ORDER BY r.month, sales_category;