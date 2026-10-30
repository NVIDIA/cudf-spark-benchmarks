WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS number_of_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
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
    GROUP BY c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.total_orders, 
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM CustomerOrders co
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.total_available_qty, 
        ss.avg_supply_cost,
        CASE 
            WHEN ss.total_available_qty > (SELECT AVG(total_available_qty) FROM SupplierStats) THEN 'Above Average'
            ELSE 'Below Average'
        END AS availability_category
    FROM SupplierStats ss
)
SELECT 
    r.o_orderkey,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    s.s_name AS supplier_name,
    l.l_quantity * l.l_extendedprice AS total_line_value,
    rc.spending_rank,
    CASE 
        WHEN l.l_discount > 0.10 THEN 'High Discount'
        ELSE 'Standard Discount'
    END AS discount_category
FROM lineitem l
JOIN orders r ON l.l_orderkey = r.o_orderkey
LEFT JOIN CustomerOrders c ON r.o_custkey = c.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN RankedOrders rc ON c.c_custkey = rc.c_custkey
WHERE r.o_orderdate >= '1997-01-01' 
AND (r.o_orderstatus = 'O' OR r.o_orderstatus IS NULL)
ORDER BY total_line_value DESC, rc.spending_rank;