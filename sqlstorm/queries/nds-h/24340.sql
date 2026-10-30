
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        RANK() OVER (ORDER BY cs.total_spend DESC) AS customer_rank
    FROM CustomerSpend cs
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal >= 1000
    GROUP BY s.s_suppkey
),
HighlySuppliedSuppliers AS (
    SELECT 
        si.s_suppkey
    FROM SupplierInfo si
    WHERE si.supplied_parts >= 5
),
FinalReport AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS return_count,
        CASE WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Frequent' ELSE 'Occasional' END AS customer_activity
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_custkey IN (SELECT c_custkey FROM TopCustomers WHERE customer_rank <= 10)
    AND o.o_orderstatus IN (SELECT o_orderstatus FROM RankedOrders WHERE rn = 1)
    AND EXISTS (SELECT 1 FROM HighlySuppliedSuppliers h WHERE h.s_suppkey = l.l_suppkey)
    GROUP BY c.c_name
)
SELECT 
    f.c_name,
    f.orders_count,
    f.total_order_value,
    f.return_count,
    f.customer_activity,
    f.orders_count * COALESCE(NULLIF(f.return_count, 0), 1) AS adjusted_order_metric
FROM FinalReport f
WHERE f.total_order_value > (SELECT AVG(total_spend) FROM CustomerSpend)
ORDER BY f.total_order_value DESC, f.c_name ASC
LIMIT 100 OFFSET 0;
