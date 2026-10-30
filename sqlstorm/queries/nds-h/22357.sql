WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < cast('1998-10-01' as date)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS account_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supply_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        CASE 
            WHEN AVG(ps.ps_supplycost) IS NULL THEN 'NA' 
            ELSE 'VALID' 
        END AS validity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
    GROUP BY p.p_partkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    cs.c_name,
    ps.p_partkey,
    ps.supply_count,
    ps.avg_supply_cost,
    ps.validity,
    'Order Status: ' || r.o_orderstatus 
        || CASE WHEN r.o_orderstatus = 'F' THEN ' (Finalized)' 
                ELSE ' (Pending)' END AS order_status_comment,
    COALESCE(NULLIF(cs.c_name, 'UNKNOWN'), 'Unnamed Customer') AS customer_safety_name
FROM RankedOrders r
JOIN CustomerRanked cs ON r.o_orderkey % cs.account_rank = 0
JOIN LineItem l ON l.l_orderkey = r.o_orderkey
JOIN PartStatistics ps ON ps.p_partkey = l.l_partkey
WHERE r.price_rank <= 10
AND NOT EXISTS (
    SELECT 1 
    FROM lineitem l2 
    WHERE l2.l_orderkey = r.o_orderkey 
    AND l2.l_returnflag = 'R'
)
ORDER BY r.o_orderdate DESC, r.o_orderkey;