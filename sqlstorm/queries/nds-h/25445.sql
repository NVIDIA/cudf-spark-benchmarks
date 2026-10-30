WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus <> 'F' AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
SelectedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size > 10
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
)
SELECT 
    sd.s_name,
    sd.s_address,
    sd.s_phone,
    sd.nation_name,
    sd.region_name,
    ao.total_revenue,
    ao.total_line_items,
    sp.p_name,
    sp.avg_supply_cost
FROM 
    SupplierDetails sd
JOIN 
    ActiveOrders ao ON sd.s_suppkey = ao.o_custkey
JOIN 
    SelectedParts sp ON ao.o_custkey = sp.p_partkey
ORDER BY 
    ao.total_revenue DESC, sd.s_name ASC
LIMIT 50;