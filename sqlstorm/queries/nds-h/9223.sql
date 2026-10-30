
WITH SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count,
        AVG(l.l_quantity) AS avg_quantity_per_item
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_order_value) AS total_spent,
        COUNT(os.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    ta.c_custkey,
    ta.c_name,
    ta.total_spent,
    sa.s_name,
    sa.total_supply_value,
    sa.num_parts
FROM 
    TopCustomers ta
JOIN 
    SupplierAggregate sa ON ta.total_spent > sa.total_supply_value
ORDER BY 
    ta.total_spent DESC, sa.total_supply_value ASC;
