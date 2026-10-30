
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_suppkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    ps.p_name,
    COALESCE(ps.total_available, 0) AS available_stock,
    co.total_spent,
    la.adjusted_revenue,
    CASE 
        WHEN co.total_orders < 5 THEN 'Low Activity'
        WHEN co.total_orders BETWEEN 5 AND 15 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS activity_level
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    PartSupplierDetails ps ON co.c_custkey = ps.s_suppkey
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = co.total_orders
WHERE 
    (ps.total_available IS NULL OR ps.total_available > 100) 
    AND co.order_rank = 1
ORDER BY 
    co.total_spent DESC, la.adjusted_revenue DESC;
