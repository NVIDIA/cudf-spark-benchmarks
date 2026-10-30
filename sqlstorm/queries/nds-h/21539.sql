WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS rank_date
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_totalprice > 1000
), SupplierPrices AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           ps.ps_availqty, ps.ps_supplycost, 
           s.s_name, s.s_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
), CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_nationkey IS NOT NULL OR c.c_comment IS NOT NULL
), OrderDetails AS (
    SELECT lo.l_orderkey, SUM(lo.l_lineitemprice) AS total_lineitem_price
    FROM (
        SELECT l.l_orderkey,
               (l.l_extendedprice * (1 - l.l_discount)) AS l_lineitemprice
        FROM lineitem l
        WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    ) AS lo
    GROUP BY lo.l_orderkey
)
SELECT DISTINCT 
    cn.c_name, 
    cn.n_name, 
    ro.o_orderkey,
    ro.o_totalprice,
    COALESCE(ps.ps_supplycost, 0) AS min_supply_cost,
    od.total_lineitem_price,
    CASE 
        WHEN ro.rank_price = 1 THEN 'Top Price'
        ELSE 'Regular'
    END AS price_category
FROM RankedOrders ro
JOIN CustomerNation cn ON cn.c_custkey = ro.o_orderkey
LEFT JOIN SupplierPrices ps ON ps.ps_partkey = ro.o_orderkey
FULL OUTER JOIN OrderDetails od ON od.l_orderkey = ro.o_orderkey
WHERE od.total_lineitem_price IS NOT NULL
  OR (ps.ps_supplycost IS NULL AND EXISTS (
      SELECT 1 FROM SupplierPrices sp WHERE sp.ps_availqty > 0
  ))
ORDER BY cn.c_name, ro.o_totalprice DESC;