WITH CustomerOrders AS (
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
FrequentItems AS (
    SELECT 
        l.l_partkey,
        COUNT(l.l_orderkey) AS order_count_per_part,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    co.c_name AS customer_name,
    fi.order_count_per_part,
    fi.total_revenue,
    ts.s_name AS supplier_name,
    ts.total_available_qty,
    ts.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    FrequentItems fi ON fi.order_count_per_part > 10
JOIN 
    TopSuppliers ts ON ts.total_supply_cost < 10000
WHERE 
    co.order_count > 5
ORDER BY 
    co.total_spent DESC, fi.total_revenue DESC;
