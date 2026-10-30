WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TotalOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           LAG(p.p_retailprice) OVER (ORDER BY p.p_partkey) AS previous_price,
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Price Missing'
               WHEN p.p_retailprice < 100.00 THEN 'Cheap'
               WHEN p.p_retailprice BETWEEN 100.00 AND 500.00 THEN 'Moderate'
               ELSE 'Expensive'
           END AS price_category
    FROM part p
    WHERE p.p_size IS NOT NULL
)
SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, ps.ps_comment,
       COALESCE(T.total_orders, 0) AS customer_order_count,
       R.s_name AS top_supplier,
       FP.price_category,
       CASE 
           WHEN R.rnk IS NOT NULL AND R.rnk <= 3 THEN 'Top Supplier'
           ELSE 'Other Supplier'
       END AS supplier_status
FROM partsupp ps
LEFT JOIN RankedSuppliers R ON ps.ps_suppkey = R.s_suppkey
LEFT JOIN TotalOrderCounts T ON R.s_suppkey = T.c_custkey 
JOIN FilteredParts FP ON ps.ps_partkey = FP.p_partkey
WHERE (R.rnk IS NULL OR R.rnk > 3)
  AND (ps.ps_availqty < 0 OR ps.ps_supplycost BETWEEN 10.00 AND 500.00)
ORDER BY supplier_status, FP.price_category DESC, ps.ps_supplycost ASC
LIMIT 100;
