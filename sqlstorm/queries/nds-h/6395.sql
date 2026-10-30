
WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supplycost DESC
    LIMIT 10
),
EligibleCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
HighPriorityOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderpriority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderpriority IN ('URGENT', 'HIGH')
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderpriority
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    TS.s_name AS Supplier_Name,
    EC.c_name AS Customer_Name,
    HPO.o_orderkey AS Order_Key,
    HPO.total_lineitem_price AS Order_Total,
    HPO.o_orderpriority AS Order_Priority
FROM TopSuppliers TS
JOIN EligibleCustomers EC ON EC.total_spent > (SELECT AVG(total_spent) FROM EligibleCustomers)
JOIN HighPriorityOrders HPO ON HPO.o_custkey = EC.c_custkey
WHERE TS.total_supplycost > 10000
ORDER BY TS.total_supplycost DESC, EC.total_spent DESC;
