
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    r.r_name,
    AVG(order_value.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT supplier.s_suppkey) AS unique_suppliers,
    MAX(supplier.supplier_rank) AS highest_supplier_rank
FROM 
    RankedSuppliers supplier
JOIN 
    HighValueOrders order_value ON supplier.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')
JOIN 
    region r ON supplier.s_nationkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
