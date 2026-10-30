
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        l.l_returnflag = 'R' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),

supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

nation_revenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(r.total_revenue), 0) AS nation_total_revenue
    FROM 
        nation n
    LEFT JOIN 
        ranked_orders r ON n.n_nationkey = (
            SELECT 
                c.c_nationkey 
            FROM 
                customer c 
            JOIN 
                orders o ON c.c_custkey = o.o_custkey
            WHERE 
                o.o_orderkey IN (SELECT o_orderkey FROM ranked_orders)
            LIMIT 1
        )
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    ns.n_name,
    ss.s_name,
    ns.nation_total_revenue,
    ss.total_supply_cost,
    CASE 
        WHEN ns.nation_total_revenue > ss.total_supply_cost THEN 'Profitable' 
        ELSE 'Not Profitable' 
    END AS profitability_status
FROM 
    nation_revenue ns
FULL OUTER JOIN 
    supplier_summary ss ON ns.n_nationkey = ss.s_suppkey
WHERE 
    (ns.nation_total_revenue IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
ORDER BY 
    ns.nation_total_revenue DESC, ss.total_supply_cost ASC;
