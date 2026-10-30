WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.total_cost
    FROM 
        supplier s
    JOIN 
        supplier_stats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.rank_within_region <= 3
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
final_report AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.s_acctbal,
        COALESCE(SUM(os.total_revenue), 0) AS total_revenue_generated
    FROM 
        top_suppliers ts
    LEFT JOIN 
        order_summary os ON ts.s_suppkey = os.o_orderkey  
    GROUP BY 
        ts.s_suppkey, ts.s_name, ts.s_acctbal
    HAVING 
        SUM(os.total_revenue) IS NULL OR SUM(os.total_revenue) > 10000
)

SELECT 
    f.s_suppkey,
    f.s_name,
    f.s_acctbal,
    f.total_revenue_generated
FROM 
    final_report f
WHERE 
    f.total_revenue_generated <> 0
ORDER BY 
    f.total_revenue_generated DESC
LIMIT 10;