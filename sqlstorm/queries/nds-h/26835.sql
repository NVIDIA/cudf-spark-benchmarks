WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cp.total_spent,
        cp.num_orders,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_custkey = c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ts.c_custkey) AS num_top_customers,
    SUM(ts.total_spent) AS total_revenue,
    AVG(ts.total_spent) AS avg_revenue_per_customer
FROM 
    TopCustomers ts
JOIN 
    nation n ON ts.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.customer_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    num_top_customers DESC;
