WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.total_order_value) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN OrderStats o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    cs.total_spent,
    ss.total_availability,
    ss.total_supply_cost,
    cs.order_count,
    s.n_name AS nation
FROM SupplierStats ss
JOIN nation s ON ss.s_suppkey = s.n_nationkey
JOIN CustomerStats cs ON cs.total_spent > ss.total_supply_cost
WHERE ss.total_availability > 1000
ORDER BY cs.total_spent DESC, ss.total_supply_cost ASC
LIMIT 10;
