
WITH SupplierAvailability AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS num_orders,
        AVG(ot.total_order_value) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderTotals ot ON o.o_orderkey = ot.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        sa.s_suppkey,
        sa.s_name,
        sa.total_available,
        sa.total_supply_cost,
        RANK() OVER (ORDER BY sa.total_available DESC) AS rank
    FROM 
        SupplierAvailability sa
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.num_orders,
    cs.avg_order_value,
    ts.total_available,
    ts.total_supply_cost
FROM 
    CustomerStats cs
LEFT JOIN 
    TopSuppliers ts ON cs.num_orders > 0 AND cs.avg_order_value > (SELECT AVG(avg_order_value) FROM CustomerStats)
WHERE 
    ts.rank <= 5
ORDER BY 
    cs.avg_order_value DESC, cs.num_orders DESC;
