WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS supplier_name,
    rs.nation_name AS supplier_nation,
    rs.total_supply_cost AS supplier_total_cost,
    co.c_name AS customer_name,
    co.total_orders AS customer_order_count,
    co.total_spent AS customer_total_spent
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrders co ON rs.rank_within_region <= 3
WHERE 
    rs.total_supply_cost > 100000
ORDER BY 
    rs.total_supply_cost DESC, co.total_spent DESC
LIMIT 10;
