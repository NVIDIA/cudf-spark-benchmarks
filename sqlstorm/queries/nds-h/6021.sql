
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        c.c_nationkey,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(sp.total_supply_cost) AS total_supply_value
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY 
        n.n_name
),
NationCustomer AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(co.total_order_value) AS total_order_value
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name AS nation,
    ns.supplier_count,
    ns.total_supply_value,
    nc.customer_count,
    nc.total_order_value
FROM 
    NationSupplier ns
JOIN 
    NationCustomer nc ON ns.n_name = nc.n_name
ORDER BY 
    ns.n_name, nc.customer_count DESC;
