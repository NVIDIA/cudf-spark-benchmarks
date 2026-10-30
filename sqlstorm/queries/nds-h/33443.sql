WITH  PriceSummary AS (
    SELECT ps_partkey, SUM(ps_supplycost) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_comment, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS account_rank
    FROM supplier s
    WHERE s.s_acctbal > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
NationsCTE AS (
    SELECT n.n_nationkey, n.n_name, r.r_name as region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierPerformance AS (
    SELECT ps.ps_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS profit,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey, p.p_name, 
    COALESCE(s.total_supply_cost, 0) AS supply_cost,
    COALESCE(sp.profit, 0) AS total_profit,
    COALESCE(c.total_spent, 0) AS customer_spending,
    n.region_name
FROM part p
LEFT JOIN PriceSummary s ON p.p_partkey = s.ps_partkey
LEFT JOIN SupplierPerformance sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN CustomerOrders c ON c.c_nationkey = (SELECT n.n_nationkey 
                                                  FROM NationsCTE n
                                                  WHERE n.n_name = 'CUSTOMER NATION') 
FULL OUTER JOIN NationsCTE n ON c.c_nationkey = n.n_nationkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)
ORDER BY p.p_partkey
LIMIT 100;