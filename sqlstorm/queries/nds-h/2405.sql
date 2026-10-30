WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_name, 
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
TopOrders AS (
    SELECT 
        oi.o_orderkey,
        oi.o_totalprice,
        oi.c_name,
        oi.c_nationkey
    FROM 
        OrderInfo oi
    WHERE 
        oi.order_rank <= 10
)
SELECT 
    t.c_name, 
    t.o_orderkey, 
    t.o_totalprice,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supplier_cost,
    COUNT(DISTINCT l.l_partkey) AS total_parts_ordered
FROM 
    TopOrders t
LEFT JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
GROUP BY 
    t.c_name, t.o_orderkey, t.o_totalprice
HAVING 
    SUM(l.l_quantity) > 20 OR SUM(ss.total_supply_cost) IS NULL
ORDER BY 
    t.o_totalprice DESC
LIMIT 50;
