WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(l.l_partkey) AS part_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        SUM(cos.total_spent) AS total_customer_revenue,
        COUNT(DISTINCT cos.c_custkey) AS unique_customers,
        AVG(sps.total_supply_value) AS average_supply_value,
        MAX(la.net_revenue) AS max_order_revenue,
        COUNT(la.l_orderkey) AS total_orders,
        CASE 
            WHEN COUNT(la.l_orderkey) > 0 THEN AVG(la.avg_quantity)
            ELSE NULL 
        END AS average_lineitem_quantity
    FROM 
        CustomerOrderSummary cos
    LEFT JOIN 
        SupplierPartSummary sps ON cos.customer_rank = sps.s_suppkey  
    JOIN 
        LineItemAnalysis la ON cos.c_custkey = la.l_orderkey  
)
SELECT *
FROM 
    FinalReport
WHERE 
    total_customer_revenue IS NOT NULL 
    AND unique_customers > 10
ORDER BY 
    total_customer_revenue DESC;