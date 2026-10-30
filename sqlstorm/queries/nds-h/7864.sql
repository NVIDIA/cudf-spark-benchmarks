WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
EnhancedLineItems AS (
    SELECT l.*, 
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           p.p_brand, p.p_type, p.p_size
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
),
SummaryData AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, ro.c_acctbal,
           SUM(eli.net_price) AS total_net_price, COUNT(eli.l_orderkey) AS line_item_count
    FROM RankedOrders ro
    LEFT JOIN EnhancedLineItems eli ON ro.o_orderkey = eli.l_orderkey
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, ro.c_acctbal
)
SELECT sd.o_orderkey, sd.o_orderdate, sd.c_name, sd.c_acctbal, sd.total_net_price, sd.line_item_count,
       rd.r_name
FROM SummaryData sd
JOIN supplier s ON sd.o_orderkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region rd ON n.n_regionkey = rd.r_regionkey
WHERE sd.line_item_count > 5
ORDER BY sd.o_orderdate DESC, sd.total_net_price DESC
LIMIT 100;