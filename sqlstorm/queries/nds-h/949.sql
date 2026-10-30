
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
QueuedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty < 50
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(tc.total_spent, 0) AS customer_spending,
    qs.total_supplycost,
    r.total_revenue,
    CASE 
        WHEN r.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status
FROM 
    RankedOrders r
FULL OUTER JOIN 
    TopCustomers tc ON r.o_orderkey = tc.c_custkey
FULL OUTER JOIN 
    QueuedSuppliers qs ON r.o_orderkey = qs.s_suppkey
WHERE 
    r.order_rank < 10 OR tc.total_spent > 20000
ORDER BY 
    r.o_orderdate DESC, tc.total_spent DESC;
