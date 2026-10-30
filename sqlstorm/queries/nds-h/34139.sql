WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           p.p_partkey, p.p_name, p.p_retailprice, 
           ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
)
SELECT nd.n_name, nd.region_name, sc.s_name, sc.p_name, 
       sc.ps_availqty, sc.ps_supplycost, 
       COUNT(DISTINCT co.o_orderkey) AS order_count,
       COALESCE(SUM(oli.total_revenue), 0) AS total_revenue_this_year
FROM SupplyChain sc
JOIN NationDetails nd ON sc.s_nationkey = nd.n_nationkey
LEFT JOIN CustomerOrders co ON sc.s_suppkey = co.c_custkey
LEFT JOIN OrderLineItems oli ON co.o_orderkey = oli.o_orderkey
WHERE sc.rn = 1
AND sc.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
GROUP BY nd.n_name, nd.region_name, sc.s_name, sc.p_name, 
         sc.ps_availqty, sc.ps_supplycost
ORDER BY total_revenue_this_year DESC, nd.n_name ASC;