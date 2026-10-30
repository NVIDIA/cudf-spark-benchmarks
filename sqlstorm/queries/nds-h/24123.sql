WITH RankedOrders AS (
    SELECT
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
), 
SupplierSummary AS (
    SELECT
        ps_partkey,
        s_suppkey,
        SUM(ps_availqty) AS total_available,
        AVG(ps_supplycost) AS avg_cost,
        COUNT(*) AS supplier_count
    FROM partsupp
    JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
    WHERE supplier.s_acctbal > 0
    GROUP BY ps_partkey, s_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
    cs.total_spent AS customer_spending,
    ss.total_available AS supplier_availability,
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R') AS total_returns
FROM part p
LEFT JOIN SupplierSummary ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN CustomerOrders cs ON cs.total_orders > 5
WHERE p.p_retailprice BETWEEN 100.00 AND 500.00
AND COALESCE(ss.avg_cost, 0) < (SELECT AVG(ps_supplycost) FROM partsupp)
OR (p.p_comment LIKE '%fragile%' AND ss.supplier_count < 5)
ORDER BY price_rank, cs.total_spent DESC
LIMIT 20 OFFSET 10;
