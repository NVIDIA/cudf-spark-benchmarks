WITH ranked_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 5
),
qualified_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(ps.ps_suppkey) > 10
),
order_line_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
final_report AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent,
        qp.p_partkey,
        qp.p_name,
        qp.supplier_count,
        qp.avg_supply_cost,
        ols.net_revenue,
        ols.distinct_parts
    FROM 
        customer_orders co
    LEFT JOIN 
        qualified_parts qp ON co.c_custkey % 10 = qp.p_partkey % 10
    JOIN 
        order_line_summary ols ON co.order_count = ols.order_line_rank
    WHERE 
        ols.net_revenue IS NOT NULL AND (qp.avg_supply_cost IS NULL OR qp.avg_supply_cost < 10000)
)
SELECT 
    r.r_name,
    COUNT(fr.p_partkey) AS total_parts,
    SUM(fr.total_spent) AS total_spent_by_customers,
    AVG(fr.avg_supply_cost) AS avg_supply_cost_per_part,
    STRING_AGG(fr.c_name || ' (' || CAST(fr.order_count AS STRING) || ' orders)', ', ') AS customer_summary
FROM 
    final_report fr
JOIN 
    nation n ON fr.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    fr.net_revenue >= (SELECT COALESCE(MIN(ols.net_revenue), 0) FROM order_line_summary ols WHERE ols.distinct_parts > 5)
GROUP BY 
    r.r_name
ORDER BY 
    total_parts DESC, total_spent_by_customers DESC
LIMIT 50 OFFSET 10;
