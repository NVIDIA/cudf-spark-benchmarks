WITH SupplierRanked AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'  
    GROUP BY o.o_orderkey, o.o_orderdate
), 
CustomerPart AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(DISTINCT p.p_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM customer c
    LEFT JOIN partsupp ps ON c.c_nationkey = ps.ps_suppkey  
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name AS region_name,
       ns.n_name AS nation_name,
       sr.s_name AS supplier_name,
       os.revenue,
       cp.part_count,
       cp.total_supply_cost
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN SupplierRanked sr ON ns.n_nationkey = sr.s_nationkey AND sr.rank = 1
JOIN OrderStats os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o 
    WHERE o.o_orderstatus = 'O'  
)
JOIN CustomerPart cp ON cp.c_custkey = os.o_orderkey  
WHERE cp.part_count > 0
ORDER BY r.r_name, ns.n_name, os.revenue DESC
LIMIT 100;