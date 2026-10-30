WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
),
CustomerOrders AS (
    SELECT 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        c.c_acctbal
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name, c.c_acctbal
),
SupplierParts AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    COALESCE(sp.total_supply_cost, 0) AS supplier_cost,
    COALESCE(sp.num_parts, 0) AS parts_count,
    CASE WHEN co.total_spent > 10000 THEN 'High Value'
         WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
         ELSE 'Low Value' END AS customer_value,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderstatus = 'O' AND ro.rn <= 10) AS top_orders_count
FROM CustomerOrders co
LEFT JOIN SupplierParts sp ON co.c_name = sp.s_name
WHERE co.c_acctbal IS NOT NULL
ORDER BY co.total_spent DESC, co.c_name;