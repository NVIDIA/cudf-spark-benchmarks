
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_category
    FROM supplier s
    WHERE s.s_name LIKE '%Corp%' OR s.s_comment LIKE '%supply%'
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand
),
CustomerActivity AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    fs.s_name AS supplier_name,
    pa.p_brand,
    pa.total_available,
    pa.avg_supply_cost,
    ca.orders_count AS customer_orders,
    ca.last_order_date,
    COALESCE(fs.balance_category, 'Unknown') AS supplier_balance
FROM RankedOrders r
LEFT JOIN FilteredSuppliers fs ON r.o_orderkey % fs.s_suppkey = 0
JOIN PartStats pa ON r.o_orderkey = pa.p_partkey
FULL OUTER JOIN CustomerActivity ca ON r.o_orderkey = ca.c_custkey
WHERE r.order_rank <= 10 AND (fs.s_acctbal IS NOT NULL OR pa.avg_supply_cost > 50.00)
ORDER BY r.o_totalprice DESC, ca.last_order_date DESC
LIMIT 20;
