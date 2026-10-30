WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
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
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.order_count, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cu.c_custkey) AS customer_count,
    SUM(hv.total_orders) AS total_value_orders,
    AVG(hv.order_count) AS avg_order_count,
    ARRAY_AGG(DISTINCT CONCAT(hv.c_name, ' (Balance: ', hv.c_acctbal, ')')) AS high_value_customers,
    (SELECT COUNT(*) FROM RankedSuppliers WHERE rn = 1) AS top_supplier_count
FROM 
    nation n
LEFT JOIN 
    customer cu ON cu.c_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueCustomers hv ON cu.c_custkey = hv.c_custkey
GROUP BY 
    n.n_name
ORDER BY 
    total_value_orders DESC;
