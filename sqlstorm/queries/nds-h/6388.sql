
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        t.s_suppkey,
        t.s_name,
        t.s_acctbal,
        t.total_supply_cost
    FROM RankedSuppliers t
    WHERE t.supply_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    ts.s_name AS supplier_name,
    ts.total_supply_cost,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN CustomerOrders co ON co.total_spent > ts.total_supply_cost
WHERE r.r_name LIKE 'N%';
