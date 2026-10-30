
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(cs.total_spent) AS total_revenue,
        SUM(ss.total_supply_cost) AS total_supply_costs
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        CustomerOrderSummary cs ON n.n_nationkey = cs.c_custkey
    JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    rs.total_revenue,
    rs.total_supply_costs,
    (rs.total_revenue - rs.total_supply_costs) AS profit
FROM 
    RegionSummary rs
WHERE 
    rs.total_revenue > 1000000
ORDER BY 
    profit DESC
LIMIT 10;
