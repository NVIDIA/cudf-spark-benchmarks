
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierPartCounts AS (
    SELECT ps.ps_partkey,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           p.p_container,
           COALESCE(spc.supplier_count, 0) AS supplier_count
    FROM part p
    LEFT JOIN SupplierPartCounts spc ON p.p_partkey = spc.ps_partkey
),
HighValueOrders AS (
    SELECT lo.l_orderkey,
           SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue
    FROM lineitem lo
    GROUP BY lo.l_orderkey
    HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
)
SELECT r.o_orderkey,
       r.o_orderdate,
       r.o_totalprice,
       pd.p_name,
       pd.p_retailprice,
       pd.supplier_count,
       CASE 
           WHEN pd.supplier_count > 5 THEN 'High'
           WHEN pd.supplier_count BETWEEN 3 AND 5 THEN 'Medium'
           ELSE 'Low' 
       END AS supplier_tier,
       COALESCE(hv.revenue, 0) AS high_value_revenue
FROM RankedOrders r
JOIN lineitem li ON r.o_orderkey = li.l_orderkey
JOIN PartDetails pd ON li.l_partkey = pd.p_partkey
LEFT JOIN HighValueOrders hv ON r.o_orderkey = hv.l_orderkey
WHERE pd.p_retailprice > 50.00
ORDER BY r.o_totalprice DESC, pd.p_name ASC
LIMIT 100;
