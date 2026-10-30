WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        ss.total_supply_value,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_value DESC) AS rnk
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    ts.s_name, 
    ts.total_supply_value, 
    ts.part_count,
    os.o_orderstatus, 
    os.total_order_value, 
    os.avg_quantity, 
    os.unique_suppliers
FROM 
    TopSuppliers ts
JOIN 
    OrderSummary os ON ts.rnk <= 10
ORDER BY 
    ts.total_supply_value DESC, 
    os.total_order_value DESC;