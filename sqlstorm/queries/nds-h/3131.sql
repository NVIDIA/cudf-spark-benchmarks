
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        ns.n_name,
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_suppkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    ts.r_name AS region_name,
    ts.s_name AS supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    TopSuppliers ts ON co.c_custkey IN (
        SELECT DISTINCT o.o_custkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_shipdate > DATE '1997-01-01'
    )
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
ORDER BY 
    co.total_spent DESC, 
    ts.total_supply_cost;