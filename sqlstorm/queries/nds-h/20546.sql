
WITH SupplierAgg AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
CustomerOrder AS (
    SELECT c_nationkey, COUNT(*) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P', 'F')
    GROUP BY c_nationkey
),
PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost,
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin,
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown Size'
               ELSE CAST(p.p_size AS STRING)
           END AS size_desc
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
MaxOrderCustomer AS (
    SELECT cust.c_nationkey, MAX(cust.total_orders) AS max_orders
    FROM CustomerOrder cust
    GROUP BY cust.c_nationkey
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_extendedprice, l.l_discount, l.l_tax,
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned'
               WHEN l.l_returnflag IS NULL THEN 'Not Returned'
               ELSE 'Normal'
           END AS return_status
    FROM lineitem l
    WHERE l.l_shipdate >= '1995-01-01'
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
       SUM(pa.profit_margin) AS total_profit_margin,
       SUM(li.net_price) AS total_net_price,
       MAX(mc.max_orders) AS maximum_orders,
       COUNT(DISTINCT li.l_orderkey) AS total_lineitems,
       MAX(CASE WHEN li.return_status = 'Returned' THEN 1 ELSE 0 END) AS any_returns,
       MAX(CASE WHEN pa.size_desc = 'Unknown Size' THEN 1 ELSE 0 END) AS any_unknown_sizes
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierAgg sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartDetail pa ON s.s_suppkey = pa.p_partkey
LEFT JOIN FilteredLineItems li ON li.l_orderkey = s.s_suppkey
LEFT JOIN MaxOrderCustomer mc ON mc.c_nationkey = n.n_nationkey
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
   AND SUM(pa.profit_margin) IS NOT NULL
   AND MAX(mc.max_orders) > 0
ORDER BY total_net_price DESC, region_name, nation_name;
