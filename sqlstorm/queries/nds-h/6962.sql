
WITH RegionalSupplierCosts AS (
    SELECT 
        r.r_name AS region_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_nationkey
),
OrderStatistics AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1994-01-01' AND '1994-12-31'
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rsc.region_name,
    os.total_orders,
    os.total_revenue,
    rsc.total_supply_cost,
    (os.total_revenue - rsc.total_supply_cost) AS profit
FROM 
    RegionalSupplierCosts rsc
JOIN 
    OrderStatistics os ON rsc.s_nationkey = os.c_nationkey
JOIN 
    region r ON rsc.region_name = r.r_name
WHERE 
    (os.total_revenue - rsc.total_supply_cost) > 0
ORDER BY 
    profit DESC;
