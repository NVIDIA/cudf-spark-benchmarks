
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS cust_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
)
SELECT 
    tc.c_name AS customer_name,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(r.s_acctbal) AS average_supplier_balance
FROM 
    TopCustomers tc
LEFT JOIN 
    orders o ON tc.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    RankedSuppliers r ON li.l_suppkey = r.s_suppkey AND r.rnk <= 3
WHERE 
    li.l_returnflag = 'N'
GROUP BY 
    tc.c_name
HAVING 
    COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
