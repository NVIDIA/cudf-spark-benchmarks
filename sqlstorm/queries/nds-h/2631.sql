WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
AdvancedOrderMetrics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    cs.total_spent,
    COALESCE(ss.total_supply_cost, 0) AS supplier_total_cost,
    ds.rnk AS order_rank
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierSummary ss ON cs.order_count = ss.part_count
LEFT JOIN 
    AdvancedOrderMetrics ds ON cs.c_custkey = ds.o_orderkey
WHERE 
    cs.total_spent >= 1000
    OR (ss.total_supply_cost IS NOT NULL AND ss.total_supply_cost > 5000)
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost ASC;
