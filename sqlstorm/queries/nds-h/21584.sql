WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) IS NOT NULL
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    co.c_custkey,
    co.c_name,
    co.total_orders,
    co.total_spent,
    r.s_suppkey,
    r.s_name,
    r.s_acctbal
FROM CustomerOrders co
LEFT JOIN RankedSuppliers r ON co.total_orders > 5 AND r.rank = 1
WHERE 
    EXISTS (SELECT 1 FROM OrderDetails od WHERE od.total_line_items > 10 AND od.net_revenue > co.total_spent / 2)
    AND co.rank_by_spending <= 10
ORDER BY 
    co.total_spent DESC, 
    r.s_acctbal DESC 
LIMIT 10 OFFSET 5;
