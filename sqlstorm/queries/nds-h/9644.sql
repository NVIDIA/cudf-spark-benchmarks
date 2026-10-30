
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name AS region_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.region_name
    FROM RankedSuppliers s
    WHERE s.rank <= 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, os.total_sales
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE c.c_acctbal > 0
),
TopCustomers AS (
    SELECT cs.c_custkey, cs.c_name, cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
)
SELECT ts.c_custkey, ts.c_name, ts.total_sales, ts.sales_rank, tps.s_suppkey, tps.s_name
FROM TopCustomers ts
JOIN TopSuppliers tps ON ts.total_sales > 10000
ORDER BY ts.sales_rank, ts.total_sales DESC;
