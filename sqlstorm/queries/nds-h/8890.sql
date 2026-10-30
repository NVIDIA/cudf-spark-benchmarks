
WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
PartSupplierStats AS (
    SELECT 
        p.p_brand, 
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_brand
),
CustomerOrderStats AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    ps.avg_supply_cost,
    ps.total_available_quantity,
    cos.order_count,
    cos.total_order_value
FROM 
    RegionStats rs
JOIN 
    PartSupplierStats ps ON rs.nation_count > 10
JOIN 
    CustomerOrderStats cos ON rs.nation_count = cos.c_nationkey
ORDER BY 
    rs.region_name, ps.avg_supply_cost DESC;
