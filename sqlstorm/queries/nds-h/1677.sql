WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_custkey
),
ranked_suppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rnk
    FROM 
        supplier_summary
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(ss.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN os.order_count IS NULL THEN 0 
        ELSE os.total_order_value 
    END AS total_sales,
    ss.total_supply_cost,
    ss.part_count
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    ranked_suppliers ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    order_summary os ON ns.n_nationkey = os.o_custkey
WHERE 
    (ss.total_supply_cost > 10000 OR ss.total_supply_cost IS NULL)
    AND (os.order_count >= 5 OR os.order_count IS NULL)
ORDER BY 
    r.r_name, total_sales DESC;