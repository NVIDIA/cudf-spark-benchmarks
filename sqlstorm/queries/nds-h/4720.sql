WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
LineItemAnalysis AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_orders_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1994-01-01' AND '1997-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    COALESCE(cs.c_name, 'Total') AS customer_name,
    ss.s_name AS supplier_name,
    ls.total_quantity,
    ls.total_revenue,
    ss.total_available_quantity,
    ss.parts_supplied,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY ss.total_available_quantity DESC) AS customer_rank,
    RANK() OVER (ORDER BY ls.total_revenue DESC) AS revenue_rank
FROM 
    LineItemAnalysis ls
FULL OUTER JOIN 
    SupplierStats ss ON ls.l_partkey = ss.s_suppkey
FULL OUTER JOIN 
    CustomerOrderStats cs ON ss.s_suppkey = cs.c_custkey
WHERE 
    ss.total_available_quantity IS NOT NULL OR cs.total_orders > 0
ORDER BY 
    customer_rank, revenue_rank;