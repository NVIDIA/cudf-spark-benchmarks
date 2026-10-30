WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        SUM(l.l_quantity) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        os.total_order_value,
        os.total_items,
        RANK() OVER (ORDER BY os.total_order_value DESC) AS rank
    FROM 
        OrderSummary os
    JOIN 
        customer c ON os.c_custkey = c.c_custkey
    WHERE 
        os.rn = 1
)
SELECT 
    ts.c_name AS customer_name,
    ts.total_order_value,
    ts.total_items,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.average_supply_cost
FROM 
    TopCustomers ts
LEFT JOIN 
    SupplierSummary ss ON ts.total_items > ss.part_count
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_order_value DESC;
