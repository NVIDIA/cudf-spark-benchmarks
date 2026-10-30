WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, 
           ps.ps_availqty, ps.ps_supplycost, 
           p.p_name, p.p_brand, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS nation_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), HighValueSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT r.o_orderkey, r.o_orderdate, r.nation_rank, 
       sc.p_name, sc.p_brand, 
       hs.total_supply_cost
FROM RankedOrders r
LEFT JOIN SupplyChain sc ON r.o_orderkey = sc.s_suppkey
FULL OUTER JOIN HighValueSuppliers hs ON sc.s_name = hs.s_name
WHERE r.nation_rank <= 5 OR hs.total_supply_cost IS NOT NULL
ORDER BY r.o_orderdate DESC, r.nation_rank;
