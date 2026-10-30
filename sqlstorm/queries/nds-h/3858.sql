WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available_qty,
        sp.avg_supply_cost
    FROM 
        SupplierPerformance sp
    WHERE 
        sp.rank_within_nation <= 3
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS ranking
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_items,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    tc.s_name,
    hvc.c_name,
    os.total_order_value,
    os.total_items,
    CASE 
        WHEN os.total_order_value > 5000 THEN 'High Value Order'
        ELSE 'Regular Order' 
    END AS order_type,
    CASE 
        WHEN os.total_items IS NULL THEN 'No Items'
        ELSE CAST(os.total_items AS STRING)
    END AS item_count
FROM 
    TopSuppliers tc
LEFT JOIN 
    HighValueCustomers hvc ON tc.s_suppkey = hvc.c_custkey
FULL OUTER JOIN 
    OrderSummary os ON hvc.c_custkey = os.o_custkey
WHERE 
    (tc.total_available_qty > 100 OR hvc.c_acctbal IS NOT NULL)
ORDER BY 
    tc.total_available_qty DESC, 
    hvc.c_acctbal DESC NULLS LAST;
