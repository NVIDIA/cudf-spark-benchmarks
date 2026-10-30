
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 5000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS AccountValue
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(s.TotalSupplyCost, 0) AS SupplierCost,
    h.c_name,
    h.AccountValue
FROM RankedOrders r
LEFT JOIN SupplierStats s ON r.o_orderkey = s.s_suppkey
LEFT JOIN HighValueCustomers h ON r.o_orderkey = h.c_custkey
WHERE r.OrderRank = 1
  AND r.o_totalprice > 1000
ORDER BY r.o_orderdate DESC, SupplierCost DESC;
