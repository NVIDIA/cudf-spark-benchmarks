
WITH  customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
part_supp_costs AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
best_suppliers AS (
    SELECT 
        p.p_partkey, 
        s.s_suppkey, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps_total.total_supply_cost) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part_supp_costs ps_total ON ps.ps_partkey = ps_total.ps_partkey
)
SELECT 
    COALESCE(co.c_name, 'Total') AS customer_name,
    COALESCE(co.o_orderkey, 0) AS order_key,
    SUM(co.o_totalprice) AS total_spent,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    MAX(bss.s_suppkey) AS top_supplier,
    p.p_name,
    p.p_retailprice,
    p.p_comment,
    bss.rn
FROM 
    customer_orders co
FULL OUTER JOIN 
    best_suppliers bss ON co.c_custkey = bss.p_partkey
JOIN 
    part p ON bss.p_partkey = p.p_partkey
WHERE 
    (co.o_orderkey IS NOT NULL OR bss.s_suppkey IS NOT NULL)
GROUP BY 
    COALESCE(co.c_name, 'Total'), 
    COALESCE(co.o_orderkey, 0), 
    p.p_name, 
    p.p_retailprice, 
    p.p_comment, 
    bss.rn
HAVING 
    SUM(co.o_totalprice) IS NOT NULL 
    AND MAX(bss.rn) = 1
ORDER BY 
    total_spent DESC NULLS LAST;
