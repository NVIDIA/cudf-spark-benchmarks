WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerCosts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(c.total_spent, 0) AS customer_total,
    COALESCE(s.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN r.OrderRank = 1 THEN 'Highest'
        ELSE 'Other'
    END AS order_priority,
    ROW_NUMBER() OVER(PARTITION BY r.o_orderdate ORDER BY r.o_totalprice DESC) AS daily_order_rank
FROM RankedOrders r
LEFT JOIN CustomerCosts c ON r.o_orderkey = c.c_custkey
LEFT JOIN SupplierInfo s ON r.o_orderkey = s.s_suppkey
WHERE r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY r.o_orderdate, r.o_totalprice DESC;