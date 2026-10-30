
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment, 
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.c_name, o.c_mktsegment
    FROM RankedOrders o
    WHERE o.rank <= 5
),
SupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name AS customer_name, 
       t.c_mktsegment, s.s_name AS supplier_name, s.p_name AS part_name, 
       s.ps_availqty, s.ps_supplycost
FROM TopOrders t
JOIN lineitem l ON t.o_orderkey = l.l_orderkey
JOIN SupplierDetails s ON l.l_partkey = s.ps_partkey
WHERE s.ps_supplycost < 100.00
ORDER BY t.o_orderdate DESC, t.o_totalprice DESC
LIMIT 50;
