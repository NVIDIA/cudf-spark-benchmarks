WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
combined_summary AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        os.total_revenue,
        os.item_count,
        ss.total_available_quantity,
        ss.average_supply_cost
    FROM 
        supplier_summary ss
    LEFT JOIN 
        order_summary os ON ss.s_suppkey = os.o_orderkey % 100
)
SELECT 
    cs.s_suppkey,
    cs.s_name,
    cs.nation_name,
    COALESCE(SUM(cs.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(cs.item_count), 0) AS total_items_sold,
    cs.total_available_quantity,
    cs.average_supply_cost,
    (COALESCE(SUM(cs.total_revenue), 0) / NULLIF(cs.average_supply_cost, 0)) AS revenue_to_cost_ratio
FROM 
    combined_summary cs
GROUP BY 
    cs.s_suppkey, cs.s_name, cs.nation_name, cs.total_available_quantity, cs.average_supply_cost
ORDER BY 
    revenue_to_cost_ratio DESC
LIMIT 10;
