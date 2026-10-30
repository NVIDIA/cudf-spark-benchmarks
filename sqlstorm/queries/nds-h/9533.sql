
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    WHERE rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    cus.c_name AS customer_name,
    cus.total_spent,
    sup.s_name AS supplier_name,
    sup.total_supply_cost
FROM CustomerOrders cus
JOIN HighCostSuppliers sup ON cus.total_spent > (SELECT AVG(total_supply_cost) FROM HighCostSuppliers)
WHERE cus.o_orderdate >= DATE '1997-01-01'
ORDER BY cus.total_spent DESC, sup.total_supply_cost DESC
LIMIT 10;
