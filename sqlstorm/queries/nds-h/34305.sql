
WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost,
           ps.ps_availqty, p.p_retailprice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size > 10
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CombinedResults AS (
    SELECT c.c_name, oh.o_orderkey, oh.o_orderdate,
           lh.total_line_value, spd.p_name, spd.ps_supplycost
    FROM HighValueCustomers c
    JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    LEFT JOIN LineItemSummary lh ON oh.o_orderkey = lh.l_orderkey
    LEFT JOIN SupplierPartDetails spd ON oh.o_orderkey = spd.p_partkey
)
SELECT 
    cr.c_name,
    cr.o_orderkey,
    cr.o_orderdate,
    COALESCE(cr.total_line_value, 0) AS total_line_value,
    cr.p_name,
    (CASE 
        WHEN cr.ps_supplycost IS NULL THEN 'Not Available'
        ELSE CAST(cr.ps_supplycost AS STRING)
     END) AS supply_cost_status
FROM CombinedResults cr
WHERE cr.o_orderdate >= '1997-01-01'
ORDER BY cr.o_orderdate DESC, cr.c_name;
