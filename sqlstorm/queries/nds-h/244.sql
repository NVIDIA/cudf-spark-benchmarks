WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    ns.total_orders AS national_orders,
    cs.c_name AS customer_name,
    ps.p_name AS part_name,
    ps.total_available_quantity,
    sc.total_supply_cost,
    oo.o_orderdate
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    (SELECT 
        n.n_nationkey, SUM(cs.total_orders) AS total_orders
     FROM 
        nation n
     JOIN 
        CustomerStats cs ON n.n_nationkey = cs.c_custkey
     GROUP BY 
        n.n_nationkey) ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN 
    CustomerStats cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    PartSupplierDetails ps ON ps.supplier_count > 0
LEFT JOIN 
    SupplierCost sc ON ps.p_partkey = sc.ps_suppkey
LEFT JOIN 
    RankedOrders oo ON oo.o_orderkey = cs.c_custkey
WHERE 
    (ns.total_orders IS NULL OR ns.total_orders > 10) 
    AND (sc.total_supply_cost IS NOT NULL AND sc.total_supply_cost > 1000.00)
ORDER BY 
    r.r_name, cs.total_orders DESC, sc.total_supply_cost ASC;
