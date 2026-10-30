
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        s.s_name AS supplier_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(SUM(sp.total_available_qty), 0) AS total_quantity_available,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT cod.c_custkey) AS customer_count,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Open'
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Other' 
    END AS order_status_label
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN 
    CustomerOrderDetails cod ON r.o_orderkey = cod.c_custkey
WHERE 
    r.rank_order = 1
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.o_totalprice, r.o_orderstatus, cod.total_order_value
HAVING 
    SUM(sp.total_supply_cost) IS NULL OR 
    SUM(sp.total_available_qty) > 0
ORDER BY 
    r.o_orderdate DESC, total_order_value DESC;
