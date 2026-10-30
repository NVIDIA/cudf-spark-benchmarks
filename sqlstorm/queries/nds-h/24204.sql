
WITH RankedSupply AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS supply_rank
    FROM partsupp
),
NationCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_nationkey, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal)
                         FROM customer c2
                         WHERE c2.c_nationkey = n.n_nationkey)
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, 
           o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > 1000
)
SELECT DISTINCT nc.nation_name, p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'N' THEN l.l_orderkey END) AS non_return_count
FROM lineitem l
INNER JOIN RankedSupply r ON l.l_partkey = r.ps_partkey AND r.supply_rank = 1
LEFT JOIN supplier s ON r.ps_suppkey = s.s_suppkey
JOIN NationCustomer nc ON s.s_nationkey = nc.n_nationkey
JOIN part p ON l.l_partkey = p.p_partkey
LEFT JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
WHERE (l.l_discount BETWEEN 0.1 AND 0.2 OR (s.s_acctbal IS NULL AND l.l_tax < 0.15))
  AND (l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-10-01')
GROUP BY nc.nation_name, p.p_brand
HAVING SUM(l.l_extendedprice) > 5000
ORDER BY total_revenue DESC,
         nc.nation_name ASC,
         p.p_brand DESC;
