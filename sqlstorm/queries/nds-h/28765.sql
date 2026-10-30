
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(rs.total_supply_cost) AS nation_supply_cost
    FROM 
        nation n
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    tn.n_name AS nation_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    MAX(co.o_totalprice) AS max_order_value,
    MIN(co.o_totalprice) AS min_order_value,
    AVG(co.o_totalprice) AS avg_order_value
FROM 
    TopNations tn
JOIN 
    CustomerOrders co ON tn.n_name = co.nation_name
GROUP BY 
    tn.n_name
ORDER BY 
    total_revenue DESC, total_orders DESC;
