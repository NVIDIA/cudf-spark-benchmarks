
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS number_of_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationPerformance AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(l.l_extendedprice, 0)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ss.s_name,
    cs.c_name,
    ns.total_sales,
    ss.total_available_quantity,
    cs.total_orders,
    cs.total_spent,
    DENSE_RANK() OVER (PARTITION BY ns.n_nationkey ORDER BY ns.total_sales DESC) AS sales_rank
FROM 
    NationPerformance ns
JOIN 
    SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrderStats cs ON ns.n_nationkey = cs.c_custkey
WHERE 
    ns.total_sales > 10000
    AND ss.average_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    ns.total_sales DESC, cs.total_spent DESC;
