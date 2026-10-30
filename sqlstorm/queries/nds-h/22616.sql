WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderdate >= DATE '1995-01-01'
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM customerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_spent > 1000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_supply_value) FROM RankedSuppliers)
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ts.s_name AS top_supplier,
    rs.total_supply_value AS regional_supply_value
FROM HighValueCustomers co
LEFT JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size = (SELECT MAX(p2.p_size) FROM part p2)))
LEFT JOIN RankedSuppliers rs ON rs.rank = 1
WHERE co.customer_rank <= 10
ORDER BY co.total_spent DESC, rs.total_supply_value DESC;