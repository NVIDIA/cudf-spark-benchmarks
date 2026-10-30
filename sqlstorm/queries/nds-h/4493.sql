WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey 
)
SELECT 
    r.s_name, 
    r.total_supply_cost, 
    c.c_name, 
    c.order_count, 
    c.total_spent, 
    o.order_value, 
    o.line_item_count
FROM 
    RankedSuppliers r
JOIN 
    nation n ON r.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = (SELECT c2.c_custkey FROM CustomerOrders c2 ORDER BY c2.total_spent DESC LIMIT 1)
LEFT JOIN 
    OrderDetails o ON o.o_orderkey = (SELECT o2.o_orderkey FROM OrderDetails o2 ORDER BY o2.order_value DESC LIMIT 1)
WHERE 
    r.rank = 1
  AND 
    n.n_name LIKE 'A%' 
ORDER BY 
    r.total_supply_cost DESC, 
    c.total_spent DESC;