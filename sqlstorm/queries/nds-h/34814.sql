
WITH  customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= CAST('1998-10-01' AS DATE) - INTERVAL '1 year'
), 

order_summary AS (
    SELECT c.c_custkey AS custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer_orders c 
    LEFT JOIN orders o ON c.o_orderkey = o.o_orderkey
    WHERE c.rn = 1
    GROUP BY c.c_custkey
),

supplier_part_data AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)

SELECT p.p_name, 
       p.p_mfgr, 
       sp.total_available, 
       sp.supplier_count,
       os.total_orders, 
       os.total_spent,
       CASE 
           WHEN os.total_spent IS NULL THEN 'No Orders' 
           ELSE 'Orders Placed'
       END AS order_status,
       CONCAT('Supplier Count: ', COALESCE(CAST(sp.supplier_count AS STRING), '0')) AS supplier_info
FROM part p
LEFT JOIN supplier_part_data sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN order_summary os ON os.custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'A%')
WHERE (sp.total_available IS NULL OR sp.total_available > 100)
  AND (os.total_orders > 0 OR os.total_spent > 1000)
ORDER BY p.p_name, os.total_spent DESC
LIMIT 50;
