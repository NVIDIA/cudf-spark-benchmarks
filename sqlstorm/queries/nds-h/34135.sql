WITH  PriceRank AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM partsupp
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_totalprice, o.o_orderstatus,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), TotalLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    tls.total_line_price,
    co.o_orderkey AS recent_order_key,
    co.o_totalprice AS recent_order_total,
    co.order_rank,
    pr.ps_supplycost,
    pr.ps_availqty
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp pr ON s.s_suppkey = pr.ps_suppkey
JOIN part p ON pr.ps_partkey = p.p_partkey
JOIN TotalLineItems tls ON tls.o_orderkey = pr.ps_partkey
JOIN CustomerOrders co ON co.o_orderkey = tls.o_orderkey
LEFT JOIN lineitem l ON l.l_orderkey = co.o_orderkey AND l.l_linenumber = 1
WHERE pr.ps_availqty > 100
  AND (l.l_shipmode = 'AIR' OR l.l_shipmode = 'TRUCK')
  AND n.n_comment IS NOT NULL
ORDER BY r.r_name, n.n_name, tls.total_line_price DESC
LIMIT 50;
