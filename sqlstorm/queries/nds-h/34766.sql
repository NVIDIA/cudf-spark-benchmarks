WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(l.l_extendedprice) AS total_extended_price
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, 
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT rh.o_orderkey, rh.o_orderstatus, rh.o_totalprice, rh.o_orderdate,
       ss.s_name, ss.part_count, ss.total_extended_price,
       co.c_name, co.order_rank
FROM OrderHierarchy rh
JOIN SupplierStats ss ON ss.total_extended_price > 10000
JOIN CustomerOrders co ON co.o_orderkey = rh.o_orderkey
WHERE rh.o_totalprice BETWEEN 500 AND 10000
  AND co.order_rank = 1
  AND ss.part_count IS NOT NULL
ORDER BY rh.o_orderdate DESC, ss.total_extended_price DESC;
