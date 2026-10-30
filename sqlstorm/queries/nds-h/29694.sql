
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_cost,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.total_supply_cost
    FROM RankedSuppliers s
    WHERE s.rank_cost <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT 
    cu.c_name AS customer_name,
    cu.order_count AS orders_made,
    cu.total_spent AS total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost AS top_supplier_cost
FROM CustomerOrders cu
JOIN TopSuppliers ts ON cu.total_spent > ts.total_supply_cost
ORDER BY cu.total_spent DESC, ts.total_supply_cost DESC;
