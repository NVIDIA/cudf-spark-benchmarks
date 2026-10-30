WITH  CustomerOrdersCTE AS (
    SELECT 
        c.c_custkey AS customer_id,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    UNION ALL
    SELECT 
        c.c_custkey AS customer_id,
        COALESCE(SUM(o_sub.o_orderkey), 0) AS order_count,
        COALESCE(SUM(o_sub.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        orders o_sub ON c.c_custkey = o_sub.o_custkey
    WHERE 
        o_sub.o_orderdate < cast('1998-10-01' as date) - INTERVAL '1' YEAR
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS amount_spent,
    s.s_name AS supplier_name,
    s.s_phone AS supplier_phone
FROM 
    customer c
LEFT JOIN 
    CustomerOrdersCTE co ON c.c_custkey = co.customer_id
JOIN 
    lineitem l ON c.c_custkey = l.l_suppkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    s.s_suppkey IN (SELECT ps_suppkey FROM TopSuppliers)
AND 
    (co.total_spent IS NULL OR co.total_spent > 1000)
ORDER BY 
    co.total_spent DESC NULLS LAST
LIMIT 50;