WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.order_count > 5
),
LargerThanAverage AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1)
)
SELECT 
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    COALESCE(c.total_spent, 0) AS customer_spending,
    CASE 
        WHEN c.customer_rank IS NOT NULL THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    lt.p_name AS expensive_part
FROM 
    lineitem l
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    TopCustomers c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    LargerThanAverage lt ON lt.p_partkey = l.l_partkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, c.total_spent, c.customer_rank, lt.p_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC, customer_spending DESC;
