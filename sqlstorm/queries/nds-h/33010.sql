WITH  SalesCTE AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT l.l_orderkey) AS order_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ss.total_sales
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.sales_rank <= 10 OR ss.sales_rank IS NULL
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COALESCE(SUM(ts.total_sales), 0) AS total_sales_by_region,
       SUM(cs.total_spent) AS total_spent_by_region,
       COUNT(DISTINCT cs.c_custkey) AS customer_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN CustomerSales cs ON cs.total_spent > 0
GROUP BY r.r_name
HAVING SUM(ts.total_sales) > 10000 OR COUNT(DISTINCT cs.c_custkey) > 5
ORDER BY total_sales_by_region DESC, customer_count DESC;