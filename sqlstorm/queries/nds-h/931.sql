
WITH SupplierLineItems AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(l.l_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        supplier s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' AND o.o_totalprice IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
RevenueByNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_nation_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    sl.s_name,
    co.c_name,
    sl.total_orders AS supplier_total_orders,
    sl.total_revenue,
    co.total_orders AS customer_total_orders,
    co.total_spent,
    rn.total_nation_revenue,
    CASE 
        WHEN sl.total_revenue > 10000 THEN 'High Performer'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM 
    SupplierLineItems sl
FULL OUTER JOIN 
    CustomerOrders co ON sl.s_suppkey = co.c_custkey
FULL OUTER JOIN 
    RevenueByNation rn ON rn.total_nation_revenue IS NOT NULL
WHERE 
    (sl.total_revenue IS NOT NULL OR co.total_spent IS NOT NULL)
ORDER BY 
    sl.total_revenue DESC, co.total_spent DESC;
