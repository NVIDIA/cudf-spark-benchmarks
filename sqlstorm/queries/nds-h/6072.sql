WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS mkt_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
FilteredLineItems AS (
    SELECT l.*, p.p_name, s.s_name
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    WHERE l.l_shipdate <= cast('1998-10-01' as date) - INTERVAL '30 days' AND l.l_discount > 0.05
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_mktsegment, COUNT(DISTINCT f.l_orderkey) AS total_line_items, SUM(f.l_extendedprice * (1 - f.l_discount)) AS total_revenue
FROM RankedOrders r
LEFT JOIN FilteredLineItems f ON r.o_orderkey = f.l_orderkey
WHERE r.mkt_rank <= 10
GROUP BY r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_mktsegment
ORDER BY r.o_totalprice DESC
LIMIT 100;