
WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
nation_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS supplier_nation,
    ns.region_name,
    COALESCE(ss.part_count, 0) AS total_parts,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    CASE 
        WHEN COALESCE(ss.part_count, 0) > 0 THEN (COALESCE(os.total_order_value, 0) / NULLIF(ss.total_value, 0))
        ELSE NULL 
    END AS efficiency_ratio
FROM 
    supplier_stats ss
FULL OUTER JOIN 
    order_summary os ON ss.s_suppkey = os.o_custkey
FULL OUTER JOIN 
    nation_info ns ON ss.s_suppkey = ns.n_nationkey OR os.o_custkey = ns.n_nationkey
WHERE 
    (ns.region_name IS NOT NULL OR ss.s_suppkey IS NOT NULL)
ORDER BY 
    efficiency_ratio DESC NULLS LAST;
