WITH OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.supplier_count,
        os.customer_count,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderStats os
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        ro.supplier_count,
        ro.customer_count
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_size,
    COALESCE(ts.total_revenue, 0) AS revenue,
    ss.unique_suppliers,
    ss.avg_supply_cost,
    CASE 
        WHEN ss.avg_supply_cost IS NULL THEN 'No Data'
        WHEN ss.avg_supply_cost > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS cost_category
FROM 
    part p
LEFT JOIN 
    TopOrders ts ON p.p_partkey = ts.o_orderkey
JOIN 
    SupplierStats ss ON ss.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_type LIKE 'METAL%'
    )
ORDER BY 
    revenue DESC, p.p_name ASC
LIMIT 20;