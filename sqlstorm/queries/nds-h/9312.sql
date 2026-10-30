
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
CustomerOrderData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent
    FROM 
        CustomerOrderData c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderData)
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.nation_name,
    rs.total_supply_cost,
    hsc.c_custkey,
    hsc.c_name,
    hsc.total_orders,
    hsc.total_spent
FROM 
    RankedSuppliers rs
JOIN 
    HighSpendCustomers hsc ON rs.rank <= 5
ORDER BY 
    rs.total_supply_cost DESC, hsc.total_spent DESC;
