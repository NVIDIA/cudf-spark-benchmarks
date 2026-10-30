WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.total_supply_value,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_value DESC) AS rn
    FROM 
        SupplierStats s
    WHERE 
        s.total_supply_value > 1000000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(od.order_total) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cu.c_name,
    cu.total_orders,
    cu.avg_order_value,
    ss.s_name AS supplier_name,
    ss.total_supply_value
FROM 
    CustomerOrders cu
LEFT JOIN 
    HighValueSuppliers ss ON cu.total_orders > 10 AND ss.rn <= 5
WHERE 
    cu.avg_order_value IS NOT NULL
ORDER BY 
    cu.avg_order_value DESC, cu.total_orders DESC;
