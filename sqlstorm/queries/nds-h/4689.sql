WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
           C.c_mktsegment
    FROM orders o
    JOIN customer C ON o.o_custkey = C.c_custkey
    WHERE C.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
),
TopOrders AS (
    SELECT r.o_orderkey,
           r.o_totalprice,
           r.o_orderdate,
           r.c_mktsegment
    FROM RankedOrders r
    WHERE r.price_rank <= 5
)
SELECT T.o_orderkey,
       T.o_totalprice,
       T.o_orderdate,
       T.c_mktsegment,
       P.p_name,
       COALESCE(S.s_name, 'Unknown Supplier') AS supplier_name,
       L.l_quantity,
       (L.l_extendedprice * (1 - L.l_discount)) AS net_price
FROM TopOrders T
LEFT JOIN lineitem L ON T.o_orderkey = L.l_orderkey
LEFT JOIN partsupp PS ON L.l_partkey = PS.ps_partkey
LEFT JOIN supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN part P ON L.l_partkey = P.p_partkey
WHERE T.o_orderdate > '1994-01-01'
  AND (T.c_mktsegment = 'FOODS' OR T.c_mktsegment IS NULL)
ORDER BY T.o_orderdate DESC, T.o_totalprice DESC;