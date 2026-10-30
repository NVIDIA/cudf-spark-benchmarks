
WITH SupplierCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.total_revenue) AS total_revenue,
    AVG(COALESCE(s.total_supply_cost, 0)) AS avg_supply_cost,
    MAX(CASE WHEN o.line_count > 5 THEN 'High Volume' ELSE 'Low Volume' END) AS order_volume_category
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    OrderStats o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierCost s ON s.ps_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice > 100.00
        )
        LIMIT 1
    )
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
ORDER BY 
    total_revenue DESC;
