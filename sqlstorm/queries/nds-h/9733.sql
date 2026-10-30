
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS region_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
ResourceIntensiveQuery AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS average_price,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        rs.total_supply_cost,
        rs.region_rank,
        rs.s_suppkey
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND rs.region_rank <= 5
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, rs.total_supply_cost, rs.region_rank, rs.s_suppkey
)
SELECT 
    r.r_name,
    AVG(rq.average_price) AS avg_price_per_region,
    SUM(rq.total_quantity) AS total_quantity_per_region,
    COUNT(DISTINCT rq.p_partkey) AS unique_parts_count
FROM 
    ResourceIntensiveQuery rq
JOIN 
    supplier s ON rq.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_quantity_per_region DESC;
