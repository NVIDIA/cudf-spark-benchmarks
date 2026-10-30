WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierAggregate AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM CustomerSummary cs
    WHERE cs.total_spent > 1000
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.total_supplycost, 0) AS total_supplycost,
    COALESCE(hu.total_spent, 0) AS top_customer_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN SupplierAggregate s ON p.p_partkey = s.ps_partkey
LEFT JOIN HighValueCustomers hu ON hu.c_custkey = (SELECT c.c_custkey 
                                                      FROM customer c 
                                                      WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                             FROM nation n 
                                                                             WHERE n.n_name = 'USA') 
                                                      ORDER BY c.c_acctbal DESC 
                                                      LIMIT 1)
WHERE p.p_size BETWEEN 10 AND 20
AND p.p_mfgr LIKE 'Manufacturer%'
AND (s.total_supplycost IS NULL OR s.total_supplycost > 5000)
ORDER BY p.p_type, p.p_retailprice DESC;