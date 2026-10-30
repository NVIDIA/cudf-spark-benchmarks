WITH SupplierStats AS (
    SELECT 
        s_suppkey,
        s_name,
        SUM(ps_supplycost * ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s_suppkey, s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.total_order_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        OrderStats o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    SUM(cs.total_orders) AS total_orders_per_region,
    AVG(cs.total_spent) AS average_spent_per_customer
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
GROUP BY 
    r.r_name
ORDER BY 
    total_orders_per_region DESC, average_spent_per_customer DESC
LIMIT 10;
