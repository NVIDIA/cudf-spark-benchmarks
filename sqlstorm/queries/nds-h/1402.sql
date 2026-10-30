
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
AggregateSales AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY l.l_suppkey
),
TopSalesSuppliers AS (
    SELECT a.l_suppkey, a.total_sales 
    FROM AggregateSales a
    JOIN RankedSuppliers r ON a.l_suppkey = r.s_suppkey
    WHERE r.rn <= 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT t.l_suppkey, t.total_sales, c.c_custkey, c.c_name, 
       COALESCE(c.order_count, 0) AS order_count, 
       COALESCE(c.total_spent, 0.00) AS total_spent,
       CASE 
           WHEN c.order_count IS NULL THEN 'No Orders' 
           ELSE 'Has Orders' 
       END AS order_status
FROM TopSalesSuppliers t
FULL OUTER JOIN CustomerOrders c ON t.l_suppkey = c.c_custkey
WHERE (t.total_sales > 10000 OR c.total_spent > 5000)
ORDER BY t.total_sales DESC NULLS LAST, c.total_spent DESC NULLS LAST;
