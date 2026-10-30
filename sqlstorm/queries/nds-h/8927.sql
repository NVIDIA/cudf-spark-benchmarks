WITH SupplierSales AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey,
           s_name,
           total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SupplierSales
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c_custkey,
           c_name,
           total_orders,
           total_spent,
           RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerOrderSummary
)
SELECT ts.s_name AS top_supplier,
       tc.c_name AS top_customer,
       ts.total_sales,
       tc.total_spent
FROM TopSuppliers ts
JOIN TopCustomers tc ON ts.sales_rank = 1 AND tc.spend_rank = 1
WHERE ts.total_sales > 1000000 AND tc.total_spent > 100000
ORDER BY ts.total_sales DESC, tc.total_spent DESC;
