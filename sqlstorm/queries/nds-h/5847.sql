WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
        o.o_orderdate, 
        COUNT(DISTINCT l.l_partkey) AS parts_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierOrderDetails AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name, 
        os.total_price, 
        os.o_orderdate, 
        os.parts_count
    FROM 
        TopSuppliers ts
    JOIN 
        lineitem l ON ts.s_suppkey = l.l_suppkey
    JOIN 
        OrderSummary os ON l.l_orderkey = os.o_orderkey
)
SELECT 
    sod.s_suppkey, 
    sod.s_name, 
    COUNT(DISTINCT sod.o_orderdate) AS order_dates_count, 
    SUM(sod.total_price) AS total_revenue, 
    AVG(sod.parts_count) AS avg_parts_per_order
FROM 
    SupplierOrderDetails sod 
GROUP BY 
    sod.s_suppkey, 
    sod.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
