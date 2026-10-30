
WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
CustomerSummary AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT ro.o_orderkey,
       cs.c_name,
       cs.total_spent,
       sd.s_name AS supplier_name,
       sd.part_count,
       ro.o_totalprice,
       ro.rank
FROM RankedOrders ro
JOIN CustomerSummary cs ON ro.o_custkey = cs.c_custkey
JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE ro.rank <= 10
ORDER BY cs.total_spent DESC, ro.o_orderdate ASC;
