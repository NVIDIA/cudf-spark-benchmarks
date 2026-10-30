
WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           SUM(ps.ps_availqty) AS total_available_quantity,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
QualifiedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           ss.total_available_quantity,
           ss.avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ss.total_available_quantity DESC) AS rank
    FROM SupplierSummary ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE ss.total_available_quantity > 0
),
TopCustomers AS (
    SELECT cus.c_custkey, 
           cus.c_name, 
           cus.total_spent, 
           ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM CustomerOrderSummary cus
    WHERE cus.order_count > 5
),
Comparison AS (
    SELECT ts.c_custkey, 
           ts.c_name AS customer_name, 
           ts.total_spent, 
           qs.s_name AS supplier_name, 
           qs.total_available_quantity,
           qs.avg_supply_cost
    FROM TopCustomers ts
    FULL OUTER JOIN QualifiedSuppliers qs ON ts.customer_rank = qs.rank
)
SELECT c.customer_name, 
       c.total_spent, 
       COALESCE(c.supplier_name, 'No Supplier') AS supplier_name, 
       COALESCE(c.total_available_quantity, 0) AS total_available_quantity,
       CASE 
           WHEN c.total_available_quantity IS NULL THEN 'N/A'
           WHEN c.total_spent >= 5000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_type
FROM Comparison c
WHERE COALESCE(c.total_spent, 0) > 0 
AND (c.total_available_quantity IS NULL OR c.total_available_quantity > 10)
ORDER BY c.total_spent DESC, c.customer_name;
