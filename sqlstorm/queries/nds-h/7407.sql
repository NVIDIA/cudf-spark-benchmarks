WITH RevenueSummary AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-10-01'
    GROUP BY 
        n.n_name
),
PartDetails AS (
    SELECT 
        p.p_name,
        COUNT(ps.ps_partkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueSummary
)
SELECT 
    t.nation_name,
    t.total_revenue,
    pd.p_name,
    pd.supplier_count,
    pd.avg_supply_cost
FROM 
    TopNations t
JOIN 
    PartDetails pd ON (t.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_extendedprice > 1000 LIMIT 1) LIMIT 1) LIMIT 1)))
WHERE 
    t.revenue_rank <= 5
ORDER BY 
    t.total_revenue DESC;