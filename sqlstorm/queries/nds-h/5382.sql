WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
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
        SUM(rs.total_supply_cost) AS aggregated_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.rn <= 5
    GROUP BY 
        s.s_nationkey
),
NationCosts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ts.aggregated_supply_cost, 0) AS total_cost
    FROM 
        nation n
    LEFT JOIN 
        TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
)
SELECT 
    rc.n_name, 
    rc.total_cost,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderdate >= '1997-01-01') AS total_orders,
    (SELECT AVG(o.o_totalprice) FROM orders o) AS avg_order_value
FROM 
    NationCosts rc
ORDER BY 
    rc.total_cost DESC, 
    rc.n_name ASC;