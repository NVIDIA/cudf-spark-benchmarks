WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),

JoinSummary AS (
    SELECT 
        ss.supplier_nation,
        co.c_name,
        co.total_order_value,
        ss.total_supply_cost
    FROM 
        CustomerOrders co
    JOIN 
        SupplierSummary ss ON co.c_custkey % 10 = ss.s_suppkey % 10
)

SELECT 
    supplier_nation,
    AVG(total_order_value) AS avg_order_value,
    SUM(total_supply_cost) AS total_supply_cost
FROM 
    JoinSummary
GROUP BY 
    supplier_nation
ORDER BY 
    supplier_nation;