WITH cte_order_totals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
cte_supplier_info AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
cte_combined AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(o.total_revenue, 0) AS total_revenue,
        o.line_count,
        o.last_order_date,
        CASE 
            WHEN o.total_revenue > 0 THEN (p.p_retailprice - COALESCE(s.total_supply_cost, 0)) / o.total_revenue 
            ELSE NULL 
        END AS profitability_ratio
    FROM 
        part p
    LEFT JOIN 
        cte_supplier_info s ON p.p_partkey = s.ps_partkey
    LEFT JOIN 
        cte_order_totals o ON p.p_partkey = o.o_orderkey
)
SELECT 
    c.p_partkey,
    c.p_name,
    c.total_supply_cost,
    c.total_revenue,
    c.profitability_ratio,
    NTILE(5) OVER (ORDER BY c.total_revenue DESC) AS revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY c.p_brand ORDER BY c.total_revenue DESC) AS brand_rank,
    CASE 
        WHEN c.last_order_date IS NULL THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status
FROM 
    cte_combined c
WHERE 
    (c.total_supply_cost > (SELECT AVG(total_supply_cost) FROM cte_supplier_info) OR c.total_revenue IS NULL)
    AND c.line_count >= 1
ORDER BY 
    c.p_partkey;
