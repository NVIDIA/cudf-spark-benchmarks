WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerRegion AS (
    SELECT c.c_custkey,
           c.c_name,
           n.n_regionkey,
           r.r_name,
           c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY c.c_acctbal DESC) AS region_rank
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT cr.c_custkey, 
       cr.c_name, 
       cr.r_name AS region_name, 
       ss.s_name AS supplier_name,
       os.total_order_value, 
       ss.total_supply_cost,
       COALESCE(os.order_count, 0) AS order_count,
       COALESCE(ss.part_count, 0) AS supplier_part_count
FROM CustomerRegion cr
LEFT JOIN OrderStats os ON cr.c_custkey = os.o_custkey
LEFT JOIN SupplierStats ss ON cr.region_rank = 1
WHERE cr.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
AND cr.r_name IS NOT NULL
ORDER BY cr.c_name, region_name;
