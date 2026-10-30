
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopSegmentOrders AS (
    SELECT r.o_orderkey, r.o_totalprice, r.c_mktsegment
    FROM RankedOrders r
    WHERE r.price_rank <= 10
),
PartSupplierSummary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT ts.o_orderkey, ts.o_totalprice, ts.c_mktsegment, p.p_name, p.p_partkey, 
       ps.total_avail_qty, ps.avg_supply_cost
FROM TopSegmentOrders ts
JOIN lineitem l ON ts.o_orderkey = l.l_orderkey
JOIN PartSupplierSummary ps ON l.l_partkey = ps.p_partkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE ps.total_avail_qty > 5 AND ts.o_totalprice > 5000
ORDER BY ts.c_mktsegment, ts.o_totalprice DESC;
