
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey,
        l.l_returnflag,
        l.l_linestatus
)
SELECT 
    cs.c_name,
    SUM(l.total_revenue) AS revenue,
    MAX(s.s_name) AS top_supplier,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    SUM(cs.order_count) AS total_orders_by_customer
FROM 
    CustomerOrders cs
JOIN 
    orders o ON cs.c_custkey = o.o_custkey
JOIN 
    LineItemSummary l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1 AND s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    l.l_linestatus = 'F' AND 
    l.total_revenue IS NOT NULL AND 
    cs.total_spent > 1000
GROUP BY 
    cs.c_custkey, cs.c_name
HAVING 
    SUM(l.total_revenue) > 50000
ORDER BY 
    revenue DESC;
