WITH supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_region_summary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    s.s_name,
    c.c_name,
    n.region_name,
    s.total_supply_cost,
    c.total_orders,
    c.total_order_value,
    n.supplier_count,
    ROW_NUMBER() OVER (PARTITION BY n.region_name ORDER BY c.total_order_value DESC) AS order_rank
FROM 
    supplier_summary s
FULL OUTER JOIN 
    customer_order_summary c ON s.s_nationkey = c.c_custkey
FULL OUTER JOIN 
    nation_region_summary n ON s.s_nationkey = n.n_nationkey
WHERE 
    (s.total_supply_cost IS NOT NULL OR c.total_order_value IS NOT NULL)
    AND n.supplier_count > 5
ORDER BY 
    n.region_name, order_rank;
