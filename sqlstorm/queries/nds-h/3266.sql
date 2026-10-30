WITH region_stats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS total_supplier_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
order_summary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        c.c_nationkey
),
lineitem_totals AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rs.r_name,
    rs.nation_count,
    rs.total_supplier_acctbal,
    os.total_order_value,
    os.order_count,
    lt.total_price_after_discount,
    lt.line_count
FROM 
    region_stats rs
LEFT JOIN 
    order_summary os ON rs.r_regionkey = os.c_nationkey
LEFT JOIN 
    lineitem_totals lt ON os.total_order_value IS NOT NULL
ORDER BY 
    rs.r_name, os.order_count DESC
LIMIT 100 OFFSET 10;