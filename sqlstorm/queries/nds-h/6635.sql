WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        SUM(cus.total_revenue) AS total_spent
    FROM 
        CustomerOrderSummary cus
    GROUP BY 
        cus.c_custkey, cus.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    tc.c_name,
    tc.total_spent
FROM 
    SupplierPartDetails sp
JOIN 
    TopCustomers tc ON sp.s_suppkey IN (
        SELECT DISTINCT s.s_suppkey
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_retailprice < 100.00
    )
ORDER BY 
    tc.total_spent DESC, sp.ps_supplycost ASC;