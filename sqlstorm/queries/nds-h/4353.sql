WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
supplier_performance AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ps.ps_suppkey
),
customers_with_high_spend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    r.r_name, 
    COALESCE(SUM(CASE WHEN rp.rank <= 10 THEN rp.total_revenue END), 0) AS top_revenue,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(COUNT(DISTINCT chs.c_custkey), 0) AS high_spending_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_performance sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    ranked_orders rp ON s.s_suppkey = rp.o_orderkey
LEFT JOIN 
    customers_with_high_spend chs ON s.s_suppkey = chs.c_custkey 
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    top_revenue DESC, total_supply_cost DESC;