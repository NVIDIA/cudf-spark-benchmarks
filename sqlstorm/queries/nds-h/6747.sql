WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RegionStats AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(CASE 
            WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice 
            ELSE 0 
        END) AS building_order_total,
        COUNT(DISTINCT o.o_orderkey) AS building_order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
) 
SELECT 
    rs.r_name AS region_name,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    rs.building_order_total,
    rs.building_order_count
FROM 
    SupplierStats ss
JOIN 
    RegionStats rs ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_type LIKE '%brass%'
        )
    )
ORDER BY 
    rs.building_order_total DESC, ss.total_supply_cost DESC
LIMIT 10;
