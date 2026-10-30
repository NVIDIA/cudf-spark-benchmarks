
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    SUM(l.l_quantity) AS total_quantity_sold,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price_after_discount,
    CASE 
        WHEN r.total_supply_cost IS NULL THEN 0
        ELSE r.total_supply_cost
    END AS supplier_total_cost
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    RankedSuppliers r ON s.s_suppkey = r.s_suppkey AND r.rank <= 5
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey = l.l_orderkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, r.total_supply_cost
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_quantity_sold DESC, avg_price_after_discount DESC;
