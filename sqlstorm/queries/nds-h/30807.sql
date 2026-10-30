WITH  RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierInfo AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS TotalAvailable,
           COUNT(DISTINCT ps.ps_partkey) AS UniqueParts,
           MAX(s.s_acctbal) AS MaxBalance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderCounts AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT order_rank.o_orderkey,
           order_rank.o_orderdate,
           order_rank.o_totalprice,
           ci.c_name,
           si.s_name,
           li.l_returnflag,
           li.l_linestatus
    FROM RankedOrders order_rank
    JOIN lineitem li ON order_rank.o_orderkey = li.l_orderkey
    JOIN SupplierInfo si ON li.l_suppkey = si.s_suppkey
    JOIN CustomerOrderCounts ci ON ci.c_custkey = li.l_orderkey
    WHERE order_rank.OrderRank <= 10
    AND (li.l_returnflag = 'R' OR li.l_linestatus = 'F')
)
SELECT hvo.o_orderkey,
       hvo.o_orderdate,
       hvo.o_totalprice,
       hvo.c_name AS Customer,
       hvo.s_name AS Supplier,
       ROW_NUMBER() OVER (PARTITION BY hvo.o_orderdate ORDER BY hvo.o_totalprice DESC) AS DailyRank
FROM HighValueOrders hvo
WHERE hvo.o_orderdate = (SELECT MAX(o_orderdate) FROM orders)
ORDER BY hvo.o_totalprice DESC
LIMIT 20;