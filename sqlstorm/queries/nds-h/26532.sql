WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS SupplierName,
    rs.total_supply_cost AS TotalSupplyCost,
    co.c_name AS CustomerName,
    co.total_orders AS TotalOrders
FROM RankedSuppliers rs
JOIN CustomerOrders co ON rs.rank <= 5
WHERE rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
ORDER BY rs.total_supply_cost DESC, co.total_orders DESC;
