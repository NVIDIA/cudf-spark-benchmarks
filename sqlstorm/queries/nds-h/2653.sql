WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
CustomerOrderHistory AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT t.s_name AS supplier_name, t.total_sales, 
       c.c_name AS customer_name, 
       c.order_count, c.total_spent
FROM TopSuppliers t
LEFT JOIN CustomerOrderHistory c ON c.order_count > 0
WHERE t.rank <= 5
ORDER BY t.total_sales DESC, c.total_spent DESC;