WITH RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_suppkey,
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
        r.r_name, s.s_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        region_name,
        s_suppkey,
        total_supply_cost,
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RegionSupplier
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_order_value,
    ts.region_name,
    ts.total_supply_cost
FROM 
    CustomerOrderDetails cs
JOIN 
    TopSuppliers ts ON cs.c_custkey = ts.s_suppkey
WHERE 
    ts.rank <= 3
ORDER BY 
    ts.region_name, cs.total_order_value DESC;
