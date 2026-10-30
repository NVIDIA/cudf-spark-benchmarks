WITH SupplierSales AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name
    FROM CustomerOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)

SELECT r.r_name,
       n.n_name,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(ss.total_sales) AS avg_supplier_sales,
       SUM(CASE 
           WHEN hv.c_custkey IS NOT NULL THEN 1 
           ELSE 0 
       END) AS high_value_customer_count
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN HighValueCustomers hv ON hv.c_custkey = s.s_suppkey
GROUP BY r.r_name, n.n_name
HAVING AVG(ss.total_sales) > (SELECT AVG(total_sales) FROM SupplierSales)
ORDER BY r.r_name, n.n_name;
