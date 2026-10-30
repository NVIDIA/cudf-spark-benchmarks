WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_regionkey, r.r_name
)
SELECT 
    cr.c_name,
    cr.r_name,
    COALESCE(ss.total_available, 0) AS total_supplier_avail,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    os.line_count,
    cr.total_orders
FROM 
    CustomerRegion cr
LEFT JOIN 
    SupplierStats ss ON cr.r_name = 'EUROPE' AND ss.total_available > 1000
LEFT JOIN 
    OrderStats os ON cr.c_custkey = os.o_custkey AND os.revenue_rank = 1
WHERE 
    cr.total_orders > 1000 OR ss.avg_supply_cost < 500
ORDER BY 
    cr.r_name, total_revenue DESC
LIMIT 10;
