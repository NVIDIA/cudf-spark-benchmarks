WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
), 
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 5000
), 
TopParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT r.r_name AS region, 
       ns.n_name AS nation, 
       COUNT(DISTINCT ro.o_orderkey) AS order_count, 
       SUM(ro.o_totalprice) AS total_value, 
       SUM(tp.total_cost) AS total_part_cost
FROM RankedOrders ro
JOIN NationSupplier ns ON ro.c_nationkey = ns.n_nationkey
JOIN region r ON ns.n_nationkey = r.r_regionkey
JOIN TopParts tp ON tp.ps_partkey = ro.o_orderkey
GROUP BY r.r_name, ns.n_name
ORDER BY total_value DESC, order_count DESC;