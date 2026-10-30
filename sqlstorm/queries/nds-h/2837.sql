WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 100
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_spent, 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    pc.p_partkey,
    pc.p_name,
    pcs.s_suppkey,
    pcs.s_name,
    pcs.ps_availqty,
    pcs.ps_supplycost,
    tc.c_name AS top_customer,
    tc.total_spent
FROM 
    part pc
JOIN 
    PartSuppliers pcs ON pc.p_partkey = pcs.ps_partkey
LEFT JOIN 
    TopCustomers tc ON pcs.s_suppkey = tc.c_custkey
WHERE 
    pcs.ps_supplycost < (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
AND 
    EXISTS (
        SELECT 1 FROM lineitem l 
        WHERE l.l_partkey = pc.p_partkey 
        AND l.l_returnflag = 'R'
    )
ORDER BY 
    pc.p_partkey, pcs.ps_supplycost DESC
LIMIT 50;
