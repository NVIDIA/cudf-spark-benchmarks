WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
SalesSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
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
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_item_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ss.s_name,
    COALESCE(ss.total_available_qty, 0) AS total_available_qty,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(ss.s_acctbal, 0) AS supplier_account_balance,
    cs.total_orders,
    cs.total_spent,
    la.total_revenue,
    la.avg_quantity
FROM 
    SupplierSummary ss
FULL OUTER JOIN 
    SalesSummary cs ON ss.s_suppkey = cs.c_custkey
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = cs.total_orders
WHERE 
    (ss.avg_supply_cost > 10.00 OR cs.total_spent > 500.00)
    AND (ss.s_acctbal IS NOT NULL OR cs.total_orders IS NOT NULL)
ORDER BY 
    ss.total_available_qty DESC, cs.total_spent DESC;
