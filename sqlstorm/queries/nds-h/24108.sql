WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.supplier_rank <= 3
),
FilteredOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),
FinalResults AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           CASE 
               WHEN t.s_name IS NOT NULL THEN 'Top Supplier'
               ELSE 'Other'
           END AS supplier_category,
           COALESCE(f.total_sales, 0) AS sales_amount,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY COALESCE(f.total_sales, 0) DESC) AS order_rank
    FROM FilteredOrders f
    FULL OUTER JOIN TopSuppliers t ON f.o_custkey = t.s_suppkey
    JOIN orders o ON f.o_orderkey = o.o_orderkey
)
SELECT r.r_name,
       COUNT(DISTINCT CASE WHEN fr.supplier_category = 'Top Supplier' THEN fr.o_orderkey END) AS top_supplier_orders,
       SUM(fr.sales_amount) AS total_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN FinalResults fr ON c.c_custkey = fr.o_custkey
GROUP BY r.r_name
HAVING SUM(fr.sales_amount) > (SELECT AVG(total_sales) FROM FilteredOrders)
ORDER BY r.r_name;
