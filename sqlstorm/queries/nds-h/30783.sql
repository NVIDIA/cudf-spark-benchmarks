
WITH  CTE_OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CTE_SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    sd.avg_supply_cost,
    sd.total_available
FROM 
    CustomerOrders cs
LEFT JOIN 
    CTE_OrderSummary os ON cs.order_count > 0
LEFT JOIN 
    CTE_SupplierDetails sd ON cs.order_count = sd.total_available
WHERE 
    (cs.total_spent > 1000 OR COALESCE(os.total_revenue, 0) > 5000)
    AND sd.avg_supply_cost IS NOT NULL
ORDER BY 
    cs.total_spent DESC, os.total_revenue DESC
LIMIT 10;
