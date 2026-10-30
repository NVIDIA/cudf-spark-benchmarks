WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
NationsWithOrders AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(co.total_spent), 0) AS national_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    n.national_revenue,
    ts.total_supply_cost,
    CASE 
        WHEN ts.total_supply_cost IS NULL THEN 'No Suppliers'
        ELSE 'Has Suppliers'
    END AS supplier_status
FROM 
    NationsWithOrders n
LEFT JOIN 
    (SELECT DISTINCT s.s_nationkey, ts.total_supply_cost 
     FROM TopSuppliers ts 
     JOIN supplier s ON s.s_suppkey = ts.s_nationkey) ts ON n.n_nationkey = ts.s_nationkey
WHERE 
    n.national_revenue > 1000000
ORDER BY 
    n.national_revenue DESC;
