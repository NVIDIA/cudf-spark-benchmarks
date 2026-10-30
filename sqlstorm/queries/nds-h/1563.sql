
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
),
HighValueOrders AS (
    SELECT cust.c_custkey, cust.c_name, cust_order.o_orderkey, cust_order.total_sales,
           CASE 
               WHEN cust_order.total_sales > 10000 THEN 'High'
               WHEN cust_order.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS sales_category
    FROM CustomerOrderDetails cust_order
    JOIN customer cust ON cust.c_custkey = cust_order.c_custkey
),
SupplierSales AS (
    SELECT r.s_suppkey, r.s_name, COUNT(DISTINCT ord.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM RankedSuppliers r
    LEFT JOIN lineitem l ON r.s_suppkey = l.l_suppkey
    LEFT JOIN orders ord ON l.l_orderkey = ord.o_orderkey
    GROUP BY r.s_suppkey, r.s_name
),
TopSuppliers AS (
    SELECT s.s_name, s.total_revenue,
           RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM SupplierSales s
)
SELECT h.sales_category, 
       COUNT(DISTINCT h.c_custkey) AS customer_count,
       SUM(h.total_sales) AS total_sales_amount,
       COALESCE(t.s_name, 'No Supplier') AS top_supplier
FROM HighValueOrders h
LEFT JOIN TopSuppliers t ON h.total_sales = t.total_revenue AND t.revenue_rank = 1
GROUP BY h.sales_category, t.s_name
ORDER BY h.sales_category;
