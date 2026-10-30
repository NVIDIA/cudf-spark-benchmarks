WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(coalesce(os.total_revenue, 0)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sc.total_cost
    FROM supplier s
    JOIN SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
)
SELECT 
    cs.c_custkey, 
    cs.c_name, 
    cs.order_count, 
    cs.total_spent, 
    ts.s_suppkey, 
    ts.s_name AS supplier_name, 
    ts.total_cost 
FROM CustomerStats cs
JOIN TopSuppliers ts ON cs.total_spent > ts.total_cost
ORDER BY cs.total_spent DESC, ts.total_cost DESC;
