WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), 
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(sp.total_available_qty, 0) AS supply_quantity,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN co.total_spent IS NULL THEN 'Not a Customer'
        ELSE 'Valued Customer'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    supplier_parts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    customer_orders co ON sp.ps_suppkey = co.c_custkey
WHERE 
    p.p_retailprice < (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size > 10
    )
ORDER BY 
    p.p_partkey;