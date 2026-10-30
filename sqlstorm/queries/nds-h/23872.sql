
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderstatus IN ('O', 'F')
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartRegion AS (
    SELECT 
        p.p_mfgr,
        r.r_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE 'N%'
    GROUP BY p.p_mfgr, r.r_name
    HAVING COUNT(DISTINCT p.p_partkey) > 5
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL AND SUM(o.o_totalprice) > 1000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    ps.total_supply_cost,
    pr.part_count,
    tc.c_name,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM RankedOrders r
LEFT JOIN SupplierSummary ps ON MOD(r.o_orderkey, 10) = MOD(ps.s_suppkey, 10)
JOIN PartRegion pr ON pr.p_mfgr = (SELECT p.p_mfgr FROM part p WHERE p.p_size = 15 LIMIT 1)
JOIN TopCustomers tc ON tc.c_custkey = MOD(r.o_orderkey, 10) 
WHERE r.order_rank <= 5 OR r.o_orderdate IS NULL
ORDER BY r.o_orderdate, tc.total_spent DESC;
