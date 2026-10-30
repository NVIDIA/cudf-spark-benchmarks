WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
OrdersSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rs.nation_name,
    rs.s_name,
    rs.total_supply_cost,
    os.order_count,
    os.total_orders
FROM 
    RankedSuppliers rs
LEFT JOIN 
    OrdersSummary os ON rs.s_suppkey = os.c_custkey
WHERE 
    rs.rank_in_region <= 5 
ORDER BY 
    rs.nation_name, rs.total_supply_cost DESC;
