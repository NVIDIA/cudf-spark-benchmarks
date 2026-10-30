WITH SupplierSum AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_container,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_container
)
SELECT pd.p_name, pd.p_brand, pd.p_retailprice, pd.p_container,
       od.o_orderkey, od.o_orderdate, od.o_totalprice,
       CASE 
           WHEN od.o_totalprice > 1000 THEN 'High Value'
           WHEN od.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS order_value_category,
       ss.total_available,
       COALESCE(ss.total_available - l.l_quantity, 0) AS available_after_order
FROM ProductDetails pd
JOIN lineitem l ON pd.p_partkey = l.l_partkey
JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
LEFT JOIN SupplierSum ss ON l.l_suppkey = ss.ps_suppkey
WHERE pd.supplier_count > 1
  AND pd.p_retailprice < (
      SELECT AVG(p2.p_retailprice) 
      FROM part p2 
      WHERE p2.p_type = 'Smartphone'
  )
ORDER BY od.o_orderdate DESC, pd.p_name;
