WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 1000
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    r.r_name,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    COALESCE(ss.total_cost, 0.00) AS supplier_total_cost,
    COUNT(DISTINCT lo.l_orderkey) AS lineitem_count,
    AVG(lo.l_discount) AS average_discount
FROM part p
LEFT JOIN SupplierStats ss ON ss.ps_partkey = p.p_partkey
LEFT JOIN lineitem lo ON lo.l_partkey = p.p_partkey
LEFT JOIN region r ON ss.s_nationkey = r.r_regionkey
LEFT JOIN CustomerOrders cs ON cs.order_count > 0
WHERE p.p_retailprice BETWEEN 100 AND 500
AND (p.p_comment IS NULL OR p.p_comment LIKE '%high%')
GROUP BY p.p_name, r.r_name, cs.order_count, cs.total_spent, ss.total_cost
HAVING SUM(lo.l_extendedprice) > 10000
ORDER BY total_spent DESC, supplier_total_cost DESC
LIMIT 50;
