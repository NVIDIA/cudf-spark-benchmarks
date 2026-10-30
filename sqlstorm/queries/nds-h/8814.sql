WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSupplier rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    sd.region_name,
    sd.nation_name,
    SUM(o.o_totalprice) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(sd.total_supply_cost) AS highest_supply_cost
FROM 
    SupplierDetails sd
JOIN 
    orders o ON sd.s_name = o.o_clerk
GROUP BY 
    sd.region_name, sd.nation_name
ORDER BY 
    total_order_value DESC, highest_supply_cost DESC;
