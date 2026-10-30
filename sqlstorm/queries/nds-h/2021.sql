
WITH supplier_performance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
region_summary AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS num_nations,
        SUM(COALESCE(lp.l_extendedprice * (1 - lp.l_discount), 0)) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem lp ON o.o_orderkey = lp.l_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
top_suppliers AS (
    SELECT 
        spp.s_suppkey, 
        spp.s_name,
        ROW_NUMBER() OVER (ORDER BY spp.total_cost DESC) AS supplier_rank
    FROM 
        supplier_performance spp
)
SELECT 
    rs.r_name, 
    rs.total_revenue, 
    ts.s_name, 
    spp.total_cost
FROM 
    region_summary rs
INNER JOIN 
    top_suppliers ts ON rs.num_nations > 0 
                    AND ts.s_suppkey IN (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey IN (SELECT DISTINCT p.p_partkey 
                                                                FROM part p 
                                                                WHERE p.p_container IS NOT NULL))
JOIN 
    supplier_performance spp ON ts.s_suppkey = spp.s_suppkey
WHERE 
    rs.total_revenue > 1000000
ORDER BY 
    rs.total_revenue DESC, 
    spp.total_cost DESC;
