WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name,
        stats.total_avail_qty,
        stats.avg_supply_cost,
        stats.part_count
    FROM 
        supplier s
    JOIN 
        SupplierStats stats ON s.s_suppkey = stats.s_suppkey
    WHERE 
        stats.rank <= 3
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_custkey
)
SELECT 
    t.s_nationkey,
    n.n_name,
    t.s_name,
    t.total_avail_qty,
    t.avg_supply_cost,
    os.total_orders,
    os.total_spent,
    os.total_quantity,
    COALESCE(os.total_orders, 0) / NULLIF(t.total_avail_qty, 0) AS order_to_supply_ratio
FROM 
    TopSuppliers t
LEFT JOIN 
    nation n ON t.s_nationkey = n.n_nationkey
LEFT JOIN 
    OrderSummary os ON t.s_suppkey = os.o_custkey 
WHERE 
    t.total_avail_qty > 1000
ORDER BY 
    t.s_nationkey, total_spent DESC;