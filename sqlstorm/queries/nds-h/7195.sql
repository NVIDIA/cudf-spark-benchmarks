WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sold DESC
    LIMIT 10
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent,
    f.order_count,
    p.p_name AS top_part_sold,
    p.total_sold
FROM 
    CustomerOrders c
JOIN 
    FrequentCustomers f ON c.c_custkey = f.c_custkey
JOIN 
    TopParts p ON p.total_sold = (
        SELECT MAX(t.total_sold) 
        FROM TopParts t
    )
ORDER BY 
    c.total_spent DESC, f.order_count DESC;