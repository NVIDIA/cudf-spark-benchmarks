
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
HighestPricedSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 0
),
CriticalOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
      AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
NegativeComments AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(CASE WHEN s.s_comment LIKE '%bad%' THEN 1 END) AS negative_feedback
    FROM customer c
    LEFT JOIN supplier s ON c.c_nationkey = s.s_nationkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    SUM(COALESCE(hp.s_acctbal, 0)) AS total_supplier_balance,
    COUNT(DISTINCT co.o_orderkey) AS num_orders,
    SUM(co.total_revenue) AS total_revenue,
    AVG(nc.negative_feedback) AS avg_negative_feedback
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighestPricedSuppliers hp ON n.n_nationkey = hp.ps_suppkey
LEFT JOIN CriticalOrders co ON co.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN NegativeComments nc ON nc.c_custkey = co.o_custkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT hp.ps_suppkey) > 5
ORDER BY total_supplier_balance DESC, r.r_name ASC
LIMIT 10;
