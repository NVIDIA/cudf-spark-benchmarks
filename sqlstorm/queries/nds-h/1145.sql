
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierCosts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           COALESCE(SC.total_supply_cost, 0) AS total_supply_cost,
           (p.p_retailprice - COALESCE(SC.total_supply_cost, 0)) AS profit_margin
    FROM part p
    LEFT JOIN SupplierCosts SC ON p.p_partkey = SC.ps_partkey
    WHERE (p.p_retailprice - COALESCE(SC.total_supply_cost, 0)) > 100
)
SELECT R.o_orderkey,
       R.o_totalprice,
       R.o_orderdate,
       R.o_orderstatus,
       HP.p_partkey,
       HP.p_name,
       HP.profit_margin,
       CASE 
           WHEN R.o_orderstatus = 'O' THEN 'Open Order'
           WHEN R.o_orderstatus = 'F' THEN 'Filled Order'
           ELSE 'Other'
       END AS order_status_desc
FROM RankedOrders R
LEFT JOIN HighValueParts HP ON R.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey IN (SELECT p.p_partkey FROM HighValueParts p)
)
WHERE R.rank_order <= 5
ORDER BY R.o_orderdate DESC, R.o_totalprice DESC;
