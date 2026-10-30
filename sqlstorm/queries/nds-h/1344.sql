WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
), supplier_part_info AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 50
), customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(total_orders, 0) AS total_orders,
        COALESCE(total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_orders co ON c.c_custkey = co.c_custkey
    WHERE 
        COALESCE(total_spent, 0) > 10000
)
SELECT 
    hvc.c_name,
    hvc.total_orders,
    hvc.total_spent,
    s.p_name,
    s.ps_supplycost
FROM 
    high_value_customers hvc
LEFT JOIN 
    supplier_part_info s ON hvc.c_custkey = s.ps_partkey
WHERE 
    hvc.total_orders > 0
    AND s.supplier_rank <= 3
ORDER BY 
    hvc.total_spent DESC, hvc.c_name ASC;