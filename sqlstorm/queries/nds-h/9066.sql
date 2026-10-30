WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.part_count,
        s.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers s
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_custkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.s_acctbal,
    t.part_count,
    t.total_supply_cost,
    os.total_order_value,
    os.total_orders
FROM 
    TopSuppliers t
JOIN 
    customer c ON t.s_suppkey = c.c_nationkey
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.o_custkey
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_supply_cost DESC, os.total_order_value DESC;