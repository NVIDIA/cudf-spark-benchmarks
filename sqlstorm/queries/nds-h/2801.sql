WITH SupplierTotal AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers, 
    COALESCE(SUM(ct.total_orders), 0) AS total_orders_by_customers,
    COALESCE(SUM(st.total_supply_cost), 0) AS total_supply_cost,
    AVG(ct.total_spent) AS avg_spent_per_customer,
    MAX(ol.total_line_item_value) AS max_order_value
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders ct ON ct.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierTotal st ON st.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey = (SELECT p.p_partkey 
                                                                 FROM part p 
                                                                 WHERE p.p_size > 20 
                                                                 ORDER BY p.p_retailprice DESC 
                                                                 LIMIT 1) 
                                          LIMIT 1)
LEFT JOIN 
    OrderLineItems ol ON ol.o_orderkey = (SELECT o.o_orderkey 
                                            FROM orders o 
                                            ORDER BY o.o_orderdate DESC 
                                            LIMIT 1)
WHERE 
    r.r_name LIKE '%West%' AND
    n.n_comment IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_orders_by_customers DESC
LIMIT 50;