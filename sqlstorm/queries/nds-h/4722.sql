WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(p.ps_availqty * p.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp p
    JOIN 
        supplier s ON p.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
),
customer_totals AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        c.c_nationkey
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        COALESCE(ct.total_spent, 0) AS total_spent,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        customer_totals ct ON n.n_nationkey = ct.c_nationkey
    LEFT JOIN 
        supplier_stats ss ON n.n_nationkey = ss.s_suppkey
)
SELECT 
    n.n_name,
    n.total_spent,
    n.total_supply_cost,
    CASE 
        WHEN n.total_spent > n.total_supply_cost THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_status,
    COUNT(DISTINCT ro.o_orderkey) AS order_count
FROM 
    nation_summary n
LEFT JOIN 
    ranked_orders ro ON n.n_nationkey = ro.o_orderkey
WHERE 
    n.total_spent IS NOT NULL OR n.total_supply_cost IS NOT NULL
GROUP BY 
    n.n_name, n.total_spent, n.total_supply_cost
ORDER BY 
    demand_status DESC, total_spent DESC;