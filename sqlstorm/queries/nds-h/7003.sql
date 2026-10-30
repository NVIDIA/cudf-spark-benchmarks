
WITH SupplyDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
), 
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    AVG(sd.total_supply_cost) AS avg_supply_cost_per_supplier
FROM 
    Nations n
JOIN 
    SupplyDetails sd ON n.n_nationkey = sd.s_nationkey
JOIN 
    CustomerOrders co ON n.n_nationkey = co.c_nationkey
JOIN 
    region r ON n.r_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;
