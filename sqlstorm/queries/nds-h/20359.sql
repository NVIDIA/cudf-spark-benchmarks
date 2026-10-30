
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartPricing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice >= (
        SELECT AVG(p2.p_retailprice) FROM part p2
        WHERE p2.p_size BETWEEN 10 AND 20
    )
),
CustomerOrders AS (
    SELECT 
        cus.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value,
        MIN(o.o_totalprice) AS min_order_value
    FROM customer cus
    JOIN orders o ON cus.c_custkey = o.o_custkey
    GROUP BY cus.c_custkey
)
SELECT 
    ns.n_name,
    CASE 
        WHEN MAX(cs.total_spent) IS NULL THEN 'No Orders'
        ELSE CAST(MAX(cs.total_spent) AS STRING)
    END AS max_spent,
    COUNT(DISTINCT ps.s_suppkey) AS total_suppliers,
    SUM(CASE 
        WHEN ps.unique_parts_supplied > 5 THEN ps.avg_supply_cost 
        ELSE 0 
    END) AS total_cost
FROM nation ns
LEFT JOIN CustomerSummary cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN SupplierDetails ps ON ns.n_nationkey = ps.s_suppkey
WHERE ns.n_name LIKE '%land%'
GROUP BY ns.n_name
HAVING COUNT(DISTINCT cs.c_custkey) > 0
ORDER BY total_suppliers DESC, max_spent DESC
LIMIT 10;
