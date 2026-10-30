WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
EligibleCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance' 
        END AS balance_status
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
LineitemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    ec.c_name,
    r.o_orderdate,
    r.o_totalprice,
    ss.avg_account_balance,
    ls.line_count,
    ls.total_price_after_discount,
    ec.balance_status
FROM RankedOrders r
LEFT JOIN EligibleCustomers ec ON r.o_orderkey = ec.c_custkey
LEFT JOIN SupplierStats ss ON ss.total_supply_value > 50000
LEFT JOIN LineitemSummary ls ON r.o_orderkey = ls.l_orderkey
WHERE r.order_rank <= 10
AND (ec.c_acctbal IS NOT NULL OR ec.balance_status = 'Sufficient Balance')
ORDER BY r.o_totalprice DESC NULLS LAST;