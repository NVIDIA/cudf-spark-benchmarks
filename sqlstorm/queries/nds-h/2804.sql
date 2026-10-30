
WITH SupplierSales AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           ss.total_sales
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND 
          (ss.total_sales IS NULL OR ss.total_sales > 50000)
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_order_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT hs.s_name AS Supplier_Name, 
       hs.total_sales AS Total_Sales, 
       COALESCE(co.total_order_value, 0) AS Customer_Order_Value
FROM HighValueSuppliers hs
LEFT JOIN CustomerOrders co ON hs.s_suppkey = co.c_custkey
WHERE LOWER(hs.s_name) LIKE '%corp%'
ORDER BY hs.total_sales DESC, co.total_order_value DESC
LIMIT 10;
