WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_acctbal 
    FROM customer c 
    WHERE c.c_acctbal IS NOT NULL 
      AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
FinalResults AS (
    SELECT r.o_orderkey,
           r.o_orderdate,
           r.o_totalprice,
           cs.total_spent,
           cs.order_count,
           ss.total_inventory_value,
           ss.unique_parts
    FROM RankedOrders r
    JOIN CustomerOrderStats cs ON r.o_orderkey = cs.total_spent
    LEFT JOIN SupplierStats ss ON ss.unique_parts > 5
    WHERE r.rn <= 10
)
SELECT f.o_orderkey, 
       f.o_orderdate, 
       f.o_totalprice,
       COALESCE(f.total_spent, 0) AS total_spent_by_customer,
       f.order_count,
       f.total_inventory_value,
       f.unique_parts
FROM FinalResults f
WHERE f.total_inventory_value IS NOT NULL
ORDER BY f.o_orderdate DESC, f.o_totalprice DESC;