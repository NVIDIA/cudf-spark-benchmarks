WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
FrequentBuyers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.total_orders,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_orders > 5
),
TopProducts AS (
    SELECT 
        l.l_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        l.l_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    fb.c_custkey,
    fb.c_name,
    fb.total_spent,
    fb.total_orders,
    tp.p_name,
    tp.total_quantity_sold
FROM 
    FrequentBuyers fb
JOIN 
    TopProducts tp ON fb.c_custkey IN (
        SELECT 
            DISTINCT o.o_custkey 
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_partkey IN (SELECT l_partkey FROM TopProducts)
    )
ORDER BY 
    fb.total_spent DESC, tp.total_quantity_sold DESC;