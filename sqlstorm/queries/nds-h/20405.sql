
WITH RankedLines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS line_rank,
        SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_order_value
    FROM 
        lineitem l
    WHERE 
        l.l_discount BETWEEN 0.0 AND 0.2
        AND l.l_quantity > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey = l.l_orderkey)
),
DistinctPartCounts AS (
    SELECT 
        l_orderkey,
        COUNT(DISTINCT l_partkey) AS distinct_parts
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.total_order_value) AS total_sales_value,
    p.p_name AS part_name,
    COALESCE(SUM(CASE WHEN l.line_rank = 1 THEN l.l_quantity ELSE 0 END), 0) AS top_line_quantity,
    COALESCE(spart.distinct_parts, 0) AS total_distinct_parts
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN 
    RankedLines l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    DistinctPartCounts spart ON o.o_orderkey = spart.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierAggregates sa ON s.s_suppkey = sa.ps_suppkey
WHERE 
    r.r_name IS NOT NULL
    AND n.n_name LIKE 'A%' 
    AND p.p_size IS NOT NULL
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name, spart.distinct_parts
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales_value DESC, region_name, nation_name, supplier_name;
