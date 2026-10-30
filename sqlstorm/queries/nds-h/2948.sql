
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE c.total_spent IS NOT NULL
)
SELECT 
    ss.s_name,
    ss.total_available,
    ss.total_parts,
    ss.avg_supply_cost,
    tc.c_name AS top_customer_name,
    tc.total_spent AS top_customer_spent,
    lcd.total_revenue
FROM SupplierStats ss
FULL OUTER JOIN TopCustomers tc ON ss.total_parts > 1
JOIN LineItemDetails lcd ON lcd.l_orderkey = (SELECT MAX(l_orderkey) FROM lineitem)
WHERE ss.avg_supply_cost > 500.00
ORDER BY ss.total_available DESC, tc.total_spent DESC
LIMIT 100;
