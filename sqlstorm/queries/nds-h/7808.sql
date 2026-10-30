WITH SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, r.r_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM SupplyChain
), TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders
)
SELECT 
    ts.s_name AS supplier_name,
    ts.nation_name,
    ts.region_name,
    ts.total_supply_cost,
    tc.c_name AS top_customer_name,
    tc.order_count,
    tc.total_spent
FROM TopSuppliers ts
JOIN TopCustomers tc ON ts.rank = tc.rank
WHERE ts.rank <= 10 AND tc.rank <= 10
ORDER BY ts.total_supply_cost DESC, tc.total_spent DESC;
