WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),

OrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders_value,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    sd.total_supply_value,
    os.total_orders_value,
    os.orders_count
FROM 
    SupplierDetails sd
LEFT JOIN 
    OrderSummary os ON sd.s_suppkey = os.c_custkey
WHERE 
    sd.total_supply_value > 10000
ORDER BY 
    sd.total_supply_value DESC, os.total_orders_value DESC;
