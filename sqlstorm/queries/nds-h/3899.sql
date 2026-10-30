WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           s.s_acctbal, COUNT(ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
RankedSuppliers AS (
    SELECT sd.*, 
           RANK() OVER (PARTITION BY sd.s_nationkey ORDER BY sd.total_supplycost DESC) AS rank_within_nation
    FROM SupplierDetails sd
)
SELECT co.c_name, 
       COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
       COALESCE(co.order_count, 0) AS total_orders,
       COALESCE(co.total_spent, 0) AS total_spent,
       rs.rank_within_nation
FROM CustomerOrders co
FULL OUTER JOIN RankedSuppliers rs ON co.c_nationkey = rs.s_nationkey
WHERE (co.total_spent > 10000 OR rs.total_supplycost IS NULL)
  AND co.c_custkey IS NOT NULL 
  AND rs.rank_within_nation <= 5
ORDER BY co.c_name, rank_within_nation DESC;
