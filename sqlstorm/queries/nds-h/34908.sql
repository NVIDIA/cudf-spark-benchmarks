WITH  customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
      AND o.o_orderdate >= '1996-01-01'
),
supplier_parts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 50
),
sales_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
       sp.p_name, sp.ps_availqty, sp.ps_supplycost, ss.total_sales
FROM customer_orders co
LEFT JOIN supplier_parts sp ON co.o_orderkey = sp.p_partkey AND sp.supply_rank = 1
LEFT JOIN sales_summary ss ON co.c_custkey = ss.c_custkey
WHERE (co.o_totalprice > 500 OR ss.total_sales IS NULL)
  AND sp.ps_supplycost IS NOT NULL
ORDER BY co.o_orderdate, ss.total_sales DESC;