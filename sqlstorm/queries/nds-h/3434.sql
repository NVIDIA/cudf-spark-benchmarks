WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT *,
           RANK() OVER (PARTITION BY total_parts ORDER BY total_supply_value DESC) AS rank_by_supply_value
    FROM 
        SupplierStats
)
SELECT 
    s.s_name,
    s.total_parts,
    s.total_supply_value,
    o.total_orders,
    o.total_spent,
    o.avg_order_value
FROM 
    RankedSuppliers s
FULL OUTER JOIN 
    OrderSummary o ON s.s_suppkey = o.c_custkey
WHERE 
    (s.total_parts >= 1 OR o.total_orders IS NULL)
    AND (s.total_supply_value > 1000 OR o.total_spent IS NULL)
ORDER BY 
    COALESCE(s.total_supply_value, 0) DESC, 
    COALESCE(o.total_spent, 0) DESC;
